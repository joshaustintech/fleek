# ADR 0162: Index scalar identity in Flay descriptors

Method candidate equality now reads scalar identity metadata from the same Prism-node descriptors that define support and mass. This keeps integer, float, string, symbol, and constant comparison rules alongside their node types, while booleans and nil remain distinguished by node type; it also fixes Flay parity for differing float literals.
