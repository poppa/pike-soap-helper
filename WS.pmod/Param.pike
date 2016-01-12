/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

//! Checks if A is an instance of B (either directly or by inheritance)
#define INSTANCE_OF(A,B) (object_program((A)) == object_program((B)) || \
                          Program.inherits(object_program((A)),         \
                          object_program(B)))

constant PIKE_STRING    = 1<<0;
constant PIKE_FLOAT     = 1<<1;
constant PIKE_INT       = 1<<2;
constant PIKE_MAPPING   = 1<<3;
constant PIKE_ARRAY     = 1<<4;
constant PIKE_MULTISET  = 1<<5;
constant PIKE_OBJECT    = 1<<6;
constant PIKE_PROGRAM   = 1<<7;
constant PIKE_FUNCTION  = 1<<8;
constant PIKE_CLASS     = 1<<9;
constant PIKE_DATE      = 1<<10;
constant PIKE_NULL      = 1<<11;

//! The parameter name
protected string name;

//! The parameter value
protected mixed value;

protected mapping(string:string) namespaces;

protected string nil;

//! Creates a new SOAP parameter
//!
//! @param _name
//! @param _value
void create(string _name, mixed _value, void|mapping(string:string) ns)
{
  name = _name;
  value = _value;
  namespaces = ns;
}

//! Returns the paramter name
string get_name()
{
  return name;
}

//! Returns the parameter value
string get_value()
{
  return value;
}

//! Sets the name of the parameter
//!
//! @param _name
void set_name(string _name)
{
  name = _name;
}

//! Sets the value of the paramter
//!
//! @param _value
void set_value(mixed _value)
{
  value = _value;
}

object_program set_nil(string val)
{
  nil = val;
  return this;
}

//! Serializes the value and creates an XML representation of the parameter
string to_xml(void|int(0..1) indent)
{
  string ns = "";

  if (namespaces) {
    ns = sprintf("%{ %s=\"%s\"%}", sort((array) namespaces));
  }

  if (nil && !value) {
    ns += " " + nil;
    return "<" + name + ns + "/>";
  }

  string res = "<" + name + ns + ">" + serialize(value) + "</" + name + ">";

  return indent ? .pretty_print_xml(res, "  ") : res;
}

//! Cast method
//!
//! @param how
mixed cast(string how)
{
  switch (how)
  {
    case "string":
    case "xml":
      return to_xml();
  }

  error("Can't cast %O() to %O\n", object_program(this), how);
}

//! Serialize the value
//!
//! @param v
protected string serialize(mixed v)
{
  string s = "";
  int type = get_pike_type(v);

  switch (type)
  {
    case PIKE_STRING:
      s += replace(v, ({ "&", "<", ">" }), ({ "&amp;", "&lt;", "&gt;" }));
      break;

    case PIKE_INT:
      s += (string)v;
      break;

    case PIKE_FLOAT:
      s += sprintf("%.2f", v);
      break;

    case PIKE_DATE:
      s += v->format_ymd() + " " + v->format_xtod();
      break;

    case PIKE_OBJECT:
      if (INSTANCE_OF(v, this)) {
        return (string) v;
      }
      /* else fall through, handle as mapping */

    case PIKE_MAPPING:
      foreach (indices(v), string key)
        s += sprintf("<%s>%s</%s>", key, serialize(v[key]), key);
      break;

    case PIKE_MULTISET:
      v = (array)v;
      /* Fall through */
    case PIKE_ARRAY:
      foreach (v, mixed av) {
        string type = pike_type_to_string(get_pike_type(av));
        if (objectp(av) && INSTANCE_OF(av, this))
          s += serialize(av);
        else
          s += sprintf("<%s>%s</%s>", type, serialize(av), type);
      }

      break;

    default:
      /* Nothing */
  }

  return s;
}

//! String format
string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(%O, %O)", object_program(this), name, value);
}

//! Check (lazy) if object @[o] is a Calendar object
//!
//! @param o
int(0..1) is_date_object(object o)
{
  return !!o->format_iso_time;
}

//! Returns a string representation of Pike type @[t]
//!
//! @param t
string pike_type_to_string(int t)
{
  return ([ PIKE_STRING   : "string",
            PIKE_FLOAT    : "float",
            PIKE_INT      : "int",
            PIKE_MAPPING  : "mapping",
            PIKE_ARRAY    : "array",
            PIKE_MULTISET : "multiset",
            PIKE_OBJECT   : "object",
            PIKE_PROGRAM  : "program",
            PIKE_FUNCTION : "function",
            PIKE_CLASS    : "class",
            PIKE_DATE     : "DateTime",
            PIKE_NULL     : "undefined" ])[t||PIKE_NULL];
}

//! Tries to find the Pike type of @[v]
//!
//! @param v
int get_pike_type(mixed v)
{
  if (stringp(v))
    return PIKE_STRING;

  if (floatp(v))
    return PIKE_FLOAT;

  if (intp(v))
    return PIKE_INT;

  if (mappingp(v))
    return PIKE_MAPPING;

  if (arrayp(v))
    return PIKE_ARRAY;

  if (multisetp(v))
    return PIKE_MULTISET;

  if (objectp(v)) {
    if (is_date_object(v))
      return PIKE_DATE;

    return PIKE_OBJECT;
  }

  if (programp(v))
    return PIKE_PROGRAM;

  if (functionp(v) || callablep(v))
    return PIKE_FUNCTION;

  return PIKE_NULL;
}

//! Returns the name part of a namespaced XML attribute
//!
//! @param m
protected mapping shorten_attributes(mapping m)
{
  mapping out = ([]);
  foreach (m||([]); string k; string v) {
    sscanf(k, "%*s:%s", k);
    out[k] = v;
  }

  return out;
}
