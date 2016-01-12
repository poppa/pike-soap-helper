/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 2 -*- */

//! The SOAP header
protected .Header header;

//! The SOAP body
protected .Body body;

//! Default namespaces
protected mapping(string:string) namespaces = ([
  "xmlns:xsi"  : "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:xsd"  : "http://www.w3.org/2001/XMLSchema",
  "xmlns:soap" : "http://schemas.xmlsoap.org/soap/envelope/"
]);

void create(void|mapping(string:string) ns)
{
  if (ns) namespaces = ns;
}

//! Set the SOAP body
//!
//! @param _body
void set_body(.Body _body)
{
  body = _body;
}

//! Set SOAP header
//!
//! @param _header
void set_header(.Header _header)
{
  header = _header;
}

//! Returns the namespaces
mapping get_namespaces()
{
  return namespaces;
}

void set_namespaces(mapping(string:string) ns)
{
  namespaces = ns;
}

//! Add a namespace
//!
//! @param ns
//!  The name of the namespace. Since this class doesn't have any mechanism
//!  for assigning namespaces this argument should be a prefixed namespace
//!  name, i.e. @expr{prefix:name@}.
//! @param value
//!  The namespace URI
void add_namespace(string ns, string value)
{
  namespaces[ns] = value;
}

string get_soap_ns()
{
  foreach (namespaces; string k; string v)
    if (v == "http://schemas.xmlsoap.org/soap/envelope/")
      return (k/":")[1];

  return "soap";
}

//! Turns the object into an XML representation of the envelope, i.e. what
//! to send in a SOAP call.
string to_xml(void|.Body _body, void|.Header _header)
{
  if (!_body && !body)
    error("Missing required body element in SOAP Envelope\n");

  string h = "";
  string ns = get_soap_ns();
  string s = "<?xml version=\"1.0\" encoding=\"utf-8\"?>";

  if (_header || header)
    h = (_header || header)->to_xml();

  return string_to_utf8(
    s + sprintf("<%s:Envelope%{ %s=\"%s\"%}>%s%s</%[0]s:Envelope>",
                ns, sort((array)namespaces), h, (_body||body)->to_xml(ns))
  );
}