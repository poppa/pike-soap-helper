/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

//! The default namespace
protected mapping(string:string) namespaces = ([]);

//! The SOAP parameters
protected array(.Param) params;

protected string name;

//! Creates a new Body object
//!
//! @param _namespace
//! @param _name
//! @param _params
void create(string|mapping(string:string) _namespace,
            string _name, void|array(.Param) _params)
{
  if (stringp(_namespace))
    namespaces->xmlns = _namespace;
  else if (mappingp(_namespace))
    namespaces = _namespace;

  name   = _name;
  params = _params;
}

//! Turns this object into an XML representation
string to_xml(void|string ns)
{
  string s = sprintf("<%s:Header>", ns || "soap");

  if (name) {
    s += sprintf("<%s%{ %s=\"%s\"%}"">%s</%[0]s>",
                 name, sizeof(namespaces) ? sort((array) namespaces) : ({}),
                 params && params->to_xml()*"" || "");
  }
  else if (params) {
    s += params->to_xml() * "";
  }
  return s + sprintf("</%s:Header>", ns || "soap");
}

mixed cast(string how)
{
  switch (how) {
    case "string": return to_xml();
  }

  error("Can't cast %O to %O\n", object_program(this), how);
}