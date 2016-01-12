inherit WS.module;

constant ENDPOINT_PROD = "http://www.webservicex.net/globalweather.asmx";
constant ENDPOINT_TEST = "http://www.webservicex.net/globalweather.asmx";

wsarray get_cities_by_country(string country)
{
  array(WS.Param) params = ({
    WS.Param("CountryName", country)
  });

  WS.Body body;
  body = WS.Body("http://www.webserviceX.NET", "GetCitiesByCountry", params);

  WS.Envelope env = WS.Envelope();

  string soap_action = "http://www.webserviceX.NET/GetCitiesByCountry";
  string res = call(soap_action, env->to_xml(body));

  Parser.XML.Tree.Node resnode = ::get_result_node(res);

  // The result is not an XML tree but rather a string, so we need to parse it
  // into XML
  Parser.XML.Tree.Node root;
  root = Parser.XML.Tree.parse_input(resnode->value_of_node());

  array(Parser.XML.Tree.Node) items = find_nodes_by_name(root, "Table");

  wsarray ret = ({});

  foreach (items, Parser.XML.Tree.Node child) {
    ret += ({ node_to_mapping(([]), child) });
  }

  return ret;
}

wsmap get_weather_by_city(string city, string country)
{
  array(WS.Param) params = ({
    WS.Param("CityName", city),
    WS.Param("CountryName", country)
  });

  WS.Body body;
  body = WS.Body("http://www.webserviceX.NET", "GetWeather", params);

  WS.Envelope env = WS.Envelope();

  string soap_action = "http://www.webserviceX.NET/GetWeather";
  string res = call(soap_action, env->to_xml(body));

  Parser.XML.Tree.Node resnode = ::get_result_node(res);
  string xml = resnode->value_of_node();
  sscanf(xml, "<?%*s?>%s", xml);
  Parser.XML.Tree.Node root;
  root = Parser.XML.Tree.parse_input(xml);
  root = find_node_by_name(root, "CurrentWeather");

  wsmap ret = node_to_mapping(([]), root);

  return ret;
}