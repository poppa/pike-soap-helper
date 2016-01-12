/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

//! All modules implementing a SOAP webservice should inherit this module.
//!
//! In a SOAP module define the two constants
//!
//! @tt{constant ENDPOINT_PROD = "uri://to.production/endpoint";@}
//! @tt{constant ENDPOINT_TEST = "uri://to.test/endpoint";@}
//!
//! If only one server exists define them both with the same URI. By default
//! the @tt{ENDPOINT_TEST@} will be used. So to make the module use the
//! production endpoint call @[set_mode()] with @[PROD_MODE] as argument.
//!
//! To use an arbitrary endpoint call @[set_endpoint()] with the URI
//! as argument.
//!
//! To trace the request and response define WS_TRACE_CALL and the entire
//! request and response will be written to stderr.
//!
//!   pike -DWS_TRACE_CALL my-program.pike
//!

#include "ws.h"

typedef mapping(string:string)         wsmap;
typedef array(wsmap)                   wsarray;
typedef mapping(string:string|wsarray) wsmap2;
typedef array(wsmap2)                  wsarray2;

Protocols.HTTP.Query query;

enum Mode {
  TEST_MODE,
  PROD_MODE
}

final void set_query(Protocols.HTTP.Query q)
{
  query = q;
}

final void set_mode(Mode _mode)
{
  mode = _mode;
}

final void set_endpoint(string endpoint)
{
  static_endpoint = endpoint;
}

private final int mode = TEST_MODE;
private string static_endpoint;
protected constant ENDPOINT_PROD = 0;
protected constant ENDPOINT_TEST = 0;

private mapping(string:string) headers = ([
  "SOAPAction"      : "",
  "Content-Type"    : "text/xml; charset=utf-8",
  "Accept-Encoding" : "gzip, deflate"
]);

string get_endpoint()
{
  if (static_endpoint) return static_endpoint;
  if (mode == TEST_MODE && ENDPOINT_TEST) return ENDPOINT_TEST;
  if (mode == PROD_MODE && ENDPOINT_PROD) return ENDPOINT_PROD;

  return ENDPOINT_TEST || ENDPOINT_PROD;
}

protected string call(string action, string envelope)
{
  mapping h = copy_value(headers);
  h->SOAPAction = action;
  h["Content-Length"] = (string) sizeof(envelope);

#ifdef WS_TRACE_ENDPOINT
  werror("> SOAP Call to: %s\n", get_endpoint());
#endif

#ifdef WS_TRACE_CALL
  werror("\n> [HTTP request - %s]\n", get_endpoint());
  foreach (h; string k; string v)
    werror("> %s: %s\n", k, v);
  string wenv = pretty_print_xml(envelope, "  ");
  werror(">\n%s\n", wenv);
  werror("----------------------------\n");
#endif

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.do_method("POST", get_endpoint(), 0, h, query, envelope);

  string data;

  data = q->data();

  if (q->headers && q->headers["content-encoding"]) {
    if (q->headers["content-encoding"] == "gzip")
      data = Gz.uncompress(data[10..<8], true);
  }

#ifdef WS_TRACE_CALL
  werror("< [HTTP response (%d)]\n", q->status);
  foreach (q->headers; string k; mixed v) {
    werror("< %s: %O\n", k, v);
  }

  string wdata;

  mixed err = catch {
    if (data)
      wdata = pretty_print_xml(data, "  ");
    else
      wdata = "(NO DATA)";
  };

  if (err)
    wdata = "(UNABLE TO PARSE XML)";

  werror("<\n%s\n", wdata);
  werror("----------------------------\n");
#endif

#ifdef WS_DUMP_RESULT
  string filename, content;
  filename = replace(action, ([ "http://"  : "",
                                "https://" : "",
                                "/"        : "_",
                                ":"        : "" ]));
  filename = filename + "-" + String.string2hex(Crypto.MD5.hash(envelope));

  content = sprintf("\n> [HTTP request - %s]\n", get_endpoint());

  foreach (h; string k; string v)
    content += sprintf("> %s: %s\n", k, v);

  content += sprintf(">\n> %s\n", envelope);
  content += "----------------------------\n";

  content += sprintf("< [HTTP response (%d)]\n", q->status);

  foreach (q->headers; string k; mixed v) {
    content += sprintf("< %s: %O\n", k, v);
  }

  content += sprintf("<\n%s\n", pretty_print_xml(data, "  "));
  content += "----------------------------\n";

  string dumpdir = combine_path(__DIR__, "dump");
  if (!Stdio.exist(dumpdir)) {
    Stdio.mkdirhier(dumpdir);
    Stdio.write_file(combine_path(dumpdir, ".nomodule"), "");
  }

  Stdio.write_file(combine_path(dumpdir, filename), content);
#endif

  if (q->status == 200) {
    return data;
  }

  if (q->status == 500) {
    PXT.Node n = PXT.parse_input(data);
    n = find_node_by_name(n, "Fault");
    PXT.Node code = find_node_by_name(n, "faultcode");
    PXT.Node str  = find_node_by_name(n, "faultstring");
    PXT.Node det  = find_node_by_name(n, "detail");
    error("SOAP error (%s): %s. %s\n",
           code && code->value_of_node() || "",
           str && str->value_of_node()   || "",
           det && det->value_of_node()   || "");
  }
  else
    error("Bad response (%d) from SOAP call!\n", q->status);
}

//! Used for pretty printing soap calls and results when debugging.
public string pretty_print_xml(string|Parser.XML.Tree.Node node,
                               void|string indent)
{
  String.Buffer b = String.Buffer();
  function add = b->add;
  int depth = 0;

  if (stringp(node))
    node = Parser.XML.Tree.parse_input(node);

  if (node->get_node_type() == Parser.XML.Tree.XML_ROOT)
    node = node->get_first_element();

  indent = indent || "\t";

  node->walk_preorder_2(
    // Enter node
    lambda (Parser.XML.Tree.Node n) {
      if (n->get_node_type() == Parser.XML.Tree.XML_TEXT) {
        add(n->value_of_node());
      }
      else {
        int nc = n->count_children();
        string name = n->get_full_name();
        string attr = sprintf("%{ %s=\"%s\"%}", (array) n->get_attributes());

        add(indent * depth, "<", name, attr, nc ? ">" : "/>\n");

        if (nc && n->get_children()[0]->get_node_type() !=
            Parser.XML.Tree.XML_TEXT)
        {
          add("\n");
        }
      }

      ++depth;
    },
    // Exit node
    lambda (Parser.XML.Tree.Node n) {
      --depth;

      if (n->count_children() == 0) {
        return;
      }

      string ind = "";
      array(Parser.XML.Tree.Node) pc = n->get_children();

      if (sizeof(pc) && pc[-1]->get_node_type() != Parser.XML.Tree.XML_TEXT) {
        ind = indent * depth;
      }

      add(ind, "</", n->get_full_name(), ">\n");
    }
  );

  return b->get();
}

protected PXT.Node find_node_by_name(PXT.Node n, string name,
                                     int(0..1)|void full)
{
  PXT.Node r;

  n->walk_preorder(
    lambda(PXT.Node cn) {
      if (cn->get_node_type() != PXT.XML_ELEMENT)
        return;

      if (full && cn->get_full_name() == name) {
        r = cn;
        return PXT.STOP_WALK;
      }
      else if (cn->get_tag_name() == name) {
        r = cn;
        return PXT.STOP_WALK;
      }
    }
  );

  return r;
}

protected PXT.Node find_node_by_id(PXT.Node n, string name,
                                   int(0..1)|void full)
{
  PXT.Node r;

  n->walk_preorder(
    lambda(PXT.Node cn) {
      if (cn->get_node_type() != PXT.XML_ELEMENT)
        return;

      string id = cn->get_attributes()["id"];

      if (id && id == name) {
        r = cn;
        return PXT.STOP_WALK;
      }
      else if (cn->get_tag_name() == name) {
        r = cn;
        return PXT.STOP_WALK;
      }
    }
  );

  return r;
}

protected array(PXT.Node) find_nodes_by_name(PXT.Node n, string name,
                                             int(0..1)|void full)
{
  array(PXT.Node) nodes = ({});

  if (!name) return ({ n });

  n->walk_preorder(
    lambda(PXT.Node n) {
      if (n->get_node_type() != PXT.XML_ELEMENT) {
        return;
      }

      if (full && n->get_full_name() == name) {
        nodes += ({ n });
      }
      else if (n->get_tag_name() == name) {
        nodes += ({ n });
      }
    }
  );

  return nodes;
}

protected PXT.Node get_result_node(string data, void|string name)
{
  if (!data || !sizeof(data))
    return 0;

  name = name || "result";

  PXT.Node n = PXT.parse_input(data);
  PXT.Node ret;

  n && n->walk_preorder(lambda(PXT.Node xn) {
    if (xn->get_node_type() == PXT.XML_ELEMENT) {
      if (search(lower_case(xn->get_tag_name()), name) > -1) {
        ret = xn;
        return PXT.STOP_WALK;
      }
    }
  });

  if (!ret) error("Unable to find result node! ");

  return ret;
}

protected mixed node_to_mapping(mapping collection, PXT.Node n)
{
  foreach (n->get_children(), PXT.Node cn) {
    if (IS_ELEMENT(cn)) {
      if (cn->count_children() > 1)
        node_to_mapping(collection[N_NAME(cn)] = ([]), cn);
      else
        collection[N_NAME(cn)] = N_VAL(cn);
    }
  }

  return collection;
}

array(.Param) sort_params(array(.Param) p)
{
  return Array.sort_array(p, lambda (.Param a, .Param b) {
    return a->get_name() > b->get_name();
  });
}

int cast_int(string s)
{
  return (int) s;
}

float cast_float(string s)
{
  return (float) replace(s, ",", ".");
}

bool cast_bool(string s)
{
  if (s == "true" || s == "1")
    return true;

  return false;
}

string sillycaps(string s)
{
  return String.sillycaps(lower_case(s));
}
