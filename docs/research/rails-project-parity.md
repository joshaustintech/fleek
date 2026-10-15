# Rails project parity receipt

## Corpus

Use JetBrains' Rails Tutorial app at commit `92ce7c470bc31952d7dc51cac15e577a948e479e` (tree `a26706bd73befbaa3d1c3cf8d2d46c3ecf41a470`). The pinned revision specifies Ruby 3.3.1 and Rails 8.0.0 and carries its MIT/Beerware notice in `LICENSE.md` (SHA-256 `79f463c320afea55eba0347bae91b0c164c807872e33afaf492a0419e5bdc308`). Do not copy its source into Fleek.

The compared input is all 25 tracked Ruby files under `app/`, selected in sorted recursive path order by `app/**/*.rb`. ERB templates are outside Fleek's Ruby input contract; do not pass the `app/` directory to Flay for comparison because Flay also analyzes `.erb` files. Neither `.reek.yml` nor `.flayignore` exists in the corpus. Settings are Reek `--smell ClassVariable` defaults and Flay default mass 16. Fleek selects both corresponding checks with default configuration and mass.

The 25-file manifest is pinned by the source commit and tree above:

```text
app/channels/application_cable/channel.rb
app/channels/application_cable/connection.rb
app/controllers/account_activations_controller.rb
app/controllers/application_controller.rb
app/controllers/microposts_controller.rb
app/controllers/password_resets_controller.rb
app/controllers/relationships_controller.rb
app/controllers/sessions_controller.rb
app/controllers/static_pages_controller.rb
app/controllers/users_controller.rb
app/helpers/account_activations_helper.rb
app/helpers/application_helper.rb
app/helpers/microposts_helper.rb
app/helpers/password_resets_helper.rb
app/helpers/relationships_helper.rb
app/helpers/sessions_helper.rb
app/helpers/static_pages_helper.rb
app/helpers/users_helper.rb
app/jobs/application_job.rb
app/mailers/application_mailer.rb
app/mailers/user_mailer.rb
app/models/application_record.rb
app/models/micropost.rb
app/models/relationship.rb
app/models/user.rb
```

## Reproduction

On Apple Silicon with the locked Fleek bundle and pinned Spinel compiler:

```sh
git clone https://github.com/JetBrains/sample_rails_app_8th_ed.git /tmp/fleek-rails-corpus
git -C /tmp/fleek-rails-corpus checkout --detach 92ce7c470bc31952d7dc51cac15e577a948e479e
SPINEL=/path/to/spinel-2026.09.12/bin/spinel make all
BUNDLE_PATH=/path/to/fleek-bundle bundle exec flay /tmp/fleek-rails-corpus/app/**/*.rb
BUNDLE_PATH=/path/to/fleek-bundle bundle exec reek --smell ClassVariable --no-progress /tmp/fleek-rails-corpus/app/**/*.rb
build/fleek --checks flay:StructuralDuplication,reek:ClassVariable /tmp/fleek-rails-corpus/app/**/*.rb
FLEEK_RAILS_CORPUS=/tmp/fleek-rails-corpus make rails-controller-parity
```

The table below is the T14 baseline at Fleek commit `dd7f86442b8e7df84e4ea3e3c1fb77b7d5de1781`, before ticket 18 added namespace support. Evidence used Ruby 3.4.9 arm64-darwin23, Flay 2.14.4, Reek 6.6.0, and Spinel 2026.09.12 / source `112bae85c1a25fc5399009a849f805bfe691426b`:

| Check | Unchanged reference | Fleek on same 25 Ruby files | Result |
| --- | --- | --- | --- |
| `reek:ClassVariable` | Exit 0; `0 total warnings` | Exit 1; 23 analyzed, 2 failed, incomplete; no findings | Incomplete due to namespaced module/class declarations in the two `app/channels/application_cable/*.rb` files. Inheritance alone is now supported. |
| `flay:StructuralDuplication` | Exit 0; score 48; one similar `:defn` group, mass 48, locations `users_controller.rb:51` and `users_controller.rb:58` | Exit 1; 0 analyzed, 25 failed, incomplete; no groups or score | Unsupported nested class methods; current Flay adapter accepts only two parameterless top-level methods. |
| Combined | Both references exit 0 | Exit 1; overall `incomplete` | Correct fail-closed behavior, but not Rails project parity. |

Flay's exact group was:

```text
Similar code found in :defn (mass = 48)
  app/controllers/users_controller.rb:51
  app/controllers/users_controller.rb:58
```

The directory-level Flay run also sees ERB templates and reports score 418; that is intentionally not compared to Fleek because it is a different source set. There are no findings edited out of the pinned corpus. Do not describe the clean Reek reference output as a successful Fleek check: the T14 baseline reported 2 namespace failures and 25 Flay failures.

## Ticket 18 follow-up

Ticket 18 supports one simple module namespace around a direct class or module. The same selected ClassVariable check was rerun on the unchanged 25-file manifest:

```text
build/fleek --checks reek:ClassVariable /tmp/fleek-rails-corpus/app/**/*.rb
Coverage: 25 selected; 25 analyzed; 0 failed; 0 excluded
Status: complete
Reek 6.6.0: 0 total warnings
Both exit statuses: 0
```

The output matches Reek's clean ClassVariable result. The combined run remains incomplete because Flay cannot analyze ordinary class methods; its baseline score-48 group is unchanged. Deeper namespace shapes and class-variable occurrences on the namespace itself fail closed. See [ADR 0021](../adr/0021-single-level-ruby-namespace-analysis.md).

## Ticket 19 implementation slice

Ticket 19's initial implementation recognized one simple class with 2–64 direct, parameterless methods when all bodies used the bounded statement grammar. It reported a single unique eligible pair and failed closed on ambiguous groups. On the pinned 25-file manifest, that version reported all 25 files incomplete. This did not close the corpus or release gate; unsupported shapes remained explicit. See [ADR 0022](../adr/0022-flay-class-method-candidate-boundary.md).

The next ticket 19 slice records class-method AST topology and exact atom values separately. Locked Flay contracts cover a Rails-shaped pair (similar `:defn`, mass/score 48, lines 2 and 9), an identical class-method pair (score 64), different call nesting that Flay leaves clean, and a qualifying nested subtree that Fleek must reject as incomplete until it can report that group. Focused mutations remove topology, alter class-method score, corrupt original line attribution, and reverse pair ordering; each is required to fail the public CLI contract.

The current implementation also retains supported findings when a class contains unsupported callbacks or methods. `make rails-controller-parity` verifies the environment points at the exact pinned commit and that `users_controller.rb` has no local changes, then analyzes the same real file with Flay 2.14.4 and Fleek. Both report one similar `:defn` group, mass 48, score 48, ordered at lines 51 and 58. Fleek labels the source `partial`, reports `0 analyzed; 1 failed`, warns that unsupported candidates may be omitted, and exits 1 with `Status: incomplete`. A synthetic Rails-shaped CLI contract also checks this partial-result behavior. ADR 0023 records why partial findings remain visible without signaling success.

The exact 25-file parity/release gate remains open. These findings and synthetic fixtures do not stand in for full manifest comparison; unsupported shapes remain incomplete. See [ADR 0022](../adr/0022-flay-class-method-candidate-boundary.md) and [ADR 0023](../adr/0023-partial-flay-findings.md).

## Ticket 19 cross-class and namespace slice

ADRs 0024–0025 add bounded candidate collection across multiple simple classes and one-level module wrappers. Public CLI contracts match Flay 2.14.4 for a `:defn` pair spanning classes and for a pair inside one namespace-wrapped class. A separate reference case reports Flay's cross-class `:class` group; Fleek returns incomplete instead of relabeling it as `:defn`.

The pinned 25-file manifest was rerun after these changes with the same default settings. Flay 2.14.4 reports score 48 and the similar `:defn` group at `users_controller.rb:51,58`; Reek 6.6.0 reports zero ClassVariable warnings. Fleek reports the same Flay group, mass, score, and locations, but marks all 25 selected files partial, reports `0 analyzed; 25 failed`, and exits 1. Its combined result therefore remains incomplete. This deliberate status difference prevents unsupported class callbacks, optional/rest/keyword/block parameters, module-level helper methods, and model DSL forms from implying complete analysis. Empty helper modules and empty namespaced classes match Flay's clean result. The null-body crash on an empty module was fixed and is covered by the CLI contract and a mutation. The required-parameter extension below does not establish complete-manifest parity or release readiness.

## Ticket 19 required-parameter slice

Class-method candidates now accept up to eight required positional parameters and local-variable reads. Optional, rest, post, keyword, keyword-rest, and block parameters remain unsupported and keep the source partial. On paired fixtures, unchanged Flay 2.14.4 and Fleek both report similar `:defn` groups at mass/score 48 with the same ordered locations, including when the methods have different required arities. A fixture whose same-named methods differ only in formal parameter names remains similar in both tools, protecting identical-group scoring. ADR 0026 records this supported boundary. The exact 25-file manifest remains incomplete pending callbacks and additional body AST support.

## Ticket 19 conditional-branch slice

Bounded `if`/`else` nodes are now supported inside class methods when their children use the existing AST grammar. On identical fixture input, pinned Flay 2.14.4 and Fleek both report one similar `:defn` group at mass/score 62 with ordered locations 2 and 14. A separate fixture puts 16 low-mass methods before the duplicated conditional pair; the 24-candidate limit retains the group past the former bound. A combined fixture proves that a possible cross-class `:class` group does not suppress the independent conditional `:defn` group; Fleek keeps the `:defn` finding and marks coverage incomplete because it cannot report the `:class` group. Together these boundaries preserve the pinned 25-file manifest's existing UsersController score-48 group. The `ElseNode` wrapper is excluded from mass, matching Flay; branch topology remains part of structural equality. Other control flow remains unsupported. This fixture result does not establish full-manifest parity.

## Ticket 19 unless-branch slice

Bounded Prism `UnlessNode` branches are now represented distinctly in class-method tree fingerprints. On identical fixture input, Flay 2.14.4 and Fleek report a similar `:defn` group at mass/score 62 with ordered locations 2 and 14. The fixture exercises block `unless` with an `else`; modifier syntax uses the same Prism node family. ADR 0028 records this addition. The exact 25-file comparison remains the release gate; this method-body extension does not cover class-level Rails DSL calls or other unsupported forms.

After this extension, `make rails-controller-parity` still passes for the pinned UsersController. On the identical 25-file manifest, Flay remains score 48 at `users_controller.rb:51,58`, and Reek remains clean. Fleek reports the same Flay group and score, Reek coverage 25/25, but Flay coverage remains 0/25 fully analyzed with 25 partial sources; combined status is incomplete and exit 1. The ticket's complete-manifest acceptance item remains open.

## Ticket 19 conditional-return slice

The class-method AST grammar now accepts Prism `ReturnNode` and `FalseNode`, including the Rails `return false if digest.nil?` form. A paired fixture matches Flay 2.14.4's similar `:defn` group at mass/score 44 and ordered lines 2/10; mutations verify that removing either node makes the public contract fail. This does not model all method body forms or class-level Rails declarations, so the full 25-file acceptance remains open. See [ADR 0029](../adr/0029-class-method-conditional-returns.md).

The exact 25-file comparison was rerun after conditional-return support. Flay remains score 48 at `users_controller.rb:51,58`; Fleek retains the matching group, reports Reek clean on all 25 files, and reports Flay coverage 0/25 fully analyzed with 25 partial sources. Combined status remains incomplete with exit 1; this slice does not alter the release gate.

## Ticket 19 local-assignment slice

Ordinary local-variable assignment nodes are now supported in class-method trees. Flay 2.14.4 and Fleek match similar `:defn` groups at mass/score 38 on ordered lines 2/10. A cross-class fixture with the same method name and otherwise matching bodies but different assigned variable names also matches as similar at mass/score 42 on lines 2/20, protecting Flay's identical-code classification. Mutations cover candidate support and name comparison. Compound assignments remain unsupported; ADR 0030 records the boundary.

The exact 25-file Rails manifest was rerun after this slice with the same selected Flay and Reek checks. Flay 2.14.4 reports total score 48 and one similar `:defn` group at `users_controller.rb:51,58`. Fleek reports the same group, locations, mass, and score; Reek analyzes all 25 files with no findings. Fleek reports Flay coverage as 25 selected, 0 analyzed, and 25 partial, overall status incomplete, and exit 1. The local-assignment slice does not change the manifest result; class-level Rails DSL and other AST forms remain uncovered, so ticket 19 stays open.

## Ticket 19 boolean-OR slice

Prism `OrNode` is now supported in bounded class-method ASTs and contributes its operator node to structural equality and mass. On identical fixture input, Flay 2.14.4 and Fleek match a similar `:defn` group at mass/score 34 and ordered lines 2/12. A focused mutation removes OR support and is caught by the public duplication contract. ADR 0031 records this boundary; class-level Rails declarations remain outside the supported candidate model.

After OR support, the exact 25-file manifest still produces Flay score 48 at `users_controller.rb:51,58`, the matching Fleek group and score, and clean Reek findings over 25/25 files. Fleek reports Flay coverage 0/25 analyzed and 25 partial, overall incomplete, exit 1. This is the recorded difference from a complete analysis and keeps the release gate open.

## Decision and next work

The real project is locked as the parity corpus, but this receipt does not prove full parity. Keep release and cold-runtime claims blocked until Fleek can analyze all relevant upstream Flay structures in ordinary Rails classes, then compare all findings, locations, grouping, score, order, and statuses on this exact manifest. Ticket 19 tracks the remaining gap; ticket 18 closes the ClassVariable namespace gap. See [ADR 0020](../adr/0020-rails-parity-corpus-and-release-gate.md).

Primary corpus references: [pinned commit](https://github.com/JetBrains/sample_rails_app_8th_ed/commit/92ce7c470bc31952d7dc51cac15e577a948e479e), [tree manifest](https://api.github.com/repos/JetBrains/sample_rails_app_8th_ed/git/trees/a26706bd73befbaa3d1c3cf8d2d46c3ecf41a470?recursive=1), [lockfile](https://github.com/JetBrains/sample_rails_app_8th_ed/blob/92ce7c470bc31952d7dc51cac15e577a948e479e/Gemfile.lock), [Ruby version](https://github.com/JetBrains/sample_rails_app_8th_ed/blob/92ce7c470bc31952d7dc51cac15e577a948e/.ruby-version), [license and notices](https://github.com/JetBrains/sample_rails_app_8th_ed/blob/92ce7c470bc31952d7dc51cac15e577a948e/LICENSE.md).
