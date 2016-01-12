int main(int argc, array(string) argv)
{
  mapping params_ns = ([
    "ns1" : "http://some.ns"
  ]);

  array(WS.Param) params = ({
    WS.Param("param1", 12),
    WS.Param("param2", ({
      WS.Param("ns:1param2-1", 21),
      WS.Param("ns1:param2-2", "a string")
    }), params_ns)
  });

  WS.Body body = WS.Body("http://myns.com/MyMethod", "data", params);
  WS.Envelope env = WS.Envelope();

  werror("%s\n", WS.pretty_print_xml(env->to_xml(body)));

  return 0;
}