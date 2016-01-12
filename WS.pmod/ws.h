#ifndef _WS_H_
#define _WS_H_

#define PXT Parser.XML.Tree

#define LOOP_RESULT(A,B,C,D) foreach (c, PXT.Node n) { \
    mapping C = ([]); \
    foreach (n->get_children(), PXT.Node B) { \
      if (B->get_node_type() == PXT.XML_ELEMENT) { \
        string key = lower_case(B->get_tag_name()),val = B->value_of_node(); \
        D \
      } \
    } \
    if (sizeof(C)) \
      A += ({ C }); \
  }

#define SCAP(S)                      String.sillycaps(lower_case (S))
#define D_ACTION(S)                  string action = S
#define D_BODY(NS, METHOD, PARAMS)   WS.Body b = WS.Body(NS, METHOD, PARAMS)
#define D_HEADER(NS, METHOD, PARAMS) WS.Header h = WS.Header(NS, METHOD, PARAMS)
#define D_ENV(BANDH...)              WS.Envelope()->to_xml(BANDH)

#define IS_ELEMENT(N) ((N)->get_node_type() == PXT.XML_ELEMENT)
#define N_NAME(S)     lower_case((S->get_tag_name()))
#define N_VAL(S)      (String.trim_all_whites((S)->value_of_node()))

#endif /* _WS_H_ */
