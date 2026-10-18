# ADR 0110: Share normalized AST candidates across method scopes

Flay compares method subtrees with structural hashes and node mass. Fleek's top-level method path instead compared statement tags, so calls with arguments were rejected and mass/identity behavior duplicated the class-method adapter.

Use the same bounded normalized AST tree for top-level parameterless methods and class methods. Structural tree markers determine shape; supported node values determine identical versus similar; the shared mass calculation counts AST nodes and excludes the same wrappers. Unsupported nodes still fail closed. This removes the separate statement-tag model and gives both method scopes one candidate algorithm.

Public contracts compare Flay 2.14.4 and Fleek for methods containing argument calls (mass/score 16), plus Ruby 4 logical-and variants with different operands and statement positions. A focused mutation disables argument-child traversal and must break the compiled CLI contract. This remains bounded support; other Flay method forms are still tracked by ticket 22.
