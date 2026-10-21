# Rails analyzer residual census (Ticket 96)

## Pinned inputs and settings

- Corpus: JetBrains Rails Tutorial at commit `92ce7c470bc31952d7dc51cac15e577a948e479e`, tree `a26706bd73befbaa3d1c3cf8d2d46c3ecf41a470`; clean detached checkout at `/private/tmp/fleek-rails-corpus-92ce`.
- Input: exactly 25 tracked `app/**/*.rb` files in sorted Git path order. The full manifest is in [the Rails parity receipt](rails-project-parity.md#corpus). ERB and generated or untracked files were not included.
- Tools: Spinel 2026.09.12, Flay 2.14.4, Reek 6.6.0.
- Reek settings: no `.reek.yml`; each of the 29 built-in detectors was run separately using its default settings and `--no-progress`. `UnusedPrivateMethod` was explicitly selected despite being opt-in.
- Flay settings: default mass 16; Fleek selected `flay:StructuralDuplication`.

Reproduce the existing baseline with `FLEEK_RAILS_CORPUS=/private/tmp/fleek-rails-corpus-92ce make rails-manifest-parity`. For each detector `D`, the Reek invocation was `bundle exec reek --smell D --no-progress <the 25 manifest files>` and Fleek was `build/fleek --checks reek:D <the same files>`. Findings below retain the reference detector, original path, line, context and message where they differ.

## Flay result

Flay 2.14.4 exits 0 with score 48 and one similar `:defn` group at `app/controllers/users_controller.rb:51,58` (mass 48). Fleek reports the same group, locations, mass and score, but exits 1: `25 selected; 0 analyzed; 25 failed; 0 excluded`, overall incomplete. The existing partial contract passes and explicitly does not claim full Flay parity. Completion remains [issue 97](../../.scratch/fleek/issues/97-rails-flay-completion-gate.md).

## Reek detector matrix

Reference status is the Reek CLI exit code followed by warning count. Fleek status is its process exit code followed by `analyzed/selected` and finding count. Exit 1 with incomplete coverage is not a clean match, even when the findings happen to match.

| Detector | Reek | Fleek | Result and coverage |
| --- | ---: | ---: | --- |
| Attribute | 2 / 3 | 2; 25/25; 3 | Findings match; complete. |
| BooleanParameter | 0 / 0 | 1; 22/25; 0 | Incomplete: `channel.rb`, `connection.rb`, `user.rb`. |
| ClassVariable | 0 / 0 | 0; 25/25; 0 | Findings match; complete. |
| ControlParameter | 0 / 0 | 1; 19/25; 1 | Extra finding in `sessions_helper.rb:36`; six sources incomplete. |
| DataClump | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| DuplicateMethodCall | 2 / 5 | 1; 19/25; 4 | Missing `SessionsController#create` at lines 7, 8, 12; six sources incomplete. |
| FeatureEnvy | 2 / 2 | 1; 19/25; 1 | Missing `UsersHelper#gravatar_for` at lines 6, 8; six sources incomplete. |
| InstanceVariableAssumption | 2 / 4 | 1; 23/25; 4 | Findings match; both `application_cable` files incomplete. |
| IrresponsibleModule | 2 / 25 | 1; 23/25; 23 | Missing warnings for both `ApplicationCable` constants at line 2; both sources incomplete. |
| LongParameterList | 0 / 0 | 1; 22/25; 0 | Incomplete: both `application_cable` files and `user.rb`. |
| LongYieldList | 0 / 0 | 1; 22/25; 0 | Incomplete: both `application_cable` files and `user.rb`. |
| ManualDispatch | 0 / 0 | 1; 19/25; 0 | Six sources incomplete. |
| MissingSafeMethod | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| ModuleInitialize | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| NestedIterators | 0 / 0 | 1; 10/25; 0 | Fifteen sources incomplete. |
| NilCheck | 2 / 4 | 1; 19/25; 3 | Missing `User#authenticated?` at line 50; six sources incomplete. |
| RepeatedConditional | 0 / 0 | 1; 19/25; 0 | Six sources incomplete. |
| SubclassedFromCoreClass | 0 / 0 | 1; 19/25; 0 | Six sources incomplete. |
| TooManyConstants | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| TooManyInstanceVariables | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| TooManyMethods | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| TooManyStatements | 2 / 7 | 1; 13/25; 0 | All seven reference findings are missing; twelve sources incomplete. |
| UncommunicativeMethodName | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| UncommunicativeModuleName | 0 / 0 | 1; 23/25; 0 | Incomplete: both `application_cable` files. |
| UncommunicativeParameterName | 0 / 0 | 1; 22/25; 0 | Incomplete: both `application_cable` files and `user.rb`. |
| UncommunicativeVariableName | 0 / 0 | 1; 21/25; 0 | Incomplete: both `application_cable` files, `micropost.rb`, and `user.rb`. |
| UnusedParameters | 0 / 0 | 1; 19/25; 0 | Six sources incomplete. |
| UtilityFunction | 2 / 1 | 1; 19/25; 1 | Finding matches; six sources incomplete. |
| UnusedPrivateMethod | 0 / 0 | 139; no report; 0 | Corpus run crashes. A one-file reproduction is tracked by [issue 127](../../.scratch/fleek/issues/127-unused-private-method-framework-subclass-crash.md). |

Exact warning deltas:

- `ControlParameter`: Fleek adds `SessionsHelper#current_user?` at line 36, “controlled by argument 'user'”; Reek reports no finding.
- `DuplicateMethodCall`: Reek reports `SessionsController#create` calls `params[:session]` three times at lines 7, 8, and 12; Fleek omits it.
- `FeatureEnvy`: Reek reports `UsersHelper#gravatar_for` referring to `user` more than `self` at lines 6 and 8; Fleek omits it.
- `IrresponsibleModule`: Fleek omits Reek's line-2 warnings for `ApplicationCable::Channel` and `ApplicationCable::Connection`.
- `NilCheck`: Reek reports `User#authenticated?` at line 50; Fleek omits it.
- `TooManyStatements`: Reek reports `AccountActivationsController#edit` line 3 (7 statements); `MicropostsController#create` line 5 (6); `PasswordResetsController#create` line 9 (7); `PasswordResetsController#update` line 25 (7); `RelationshipsController#create` line 4 (6); `RelationshipsController#destroy` line 13 (6); and `SessionsController#create` line 6 (13). Fleek reports none.

## Incomplete source shapes

Fleek's per-check source errors show these repeated groups; the specific supported grammar is printed in each report's `Scope limits` line.

| Detector group | Failed sources |
| --- | --- |
| DataClump, InstanceVariableAssumption, IrresponsibleModule, MissingSafeMethod, ModuleInitialize, TooManyConstants, TooManyInstanceVariables, TooManyMethods, UncommunicativeMethodName, UncommunicativeModuleName | `channels/application_cable/channel.rb`; `channels/application_cable/connection.rb` |
| BooleanParameter, LongParameterList, LongYieldList, UncommunicativeParameterName | Both `application_cable` files; `models/user.rb` |
| UncommunicativeVariableName | Both `application_cable` files; `models/micropost.rb`; `models/user.rb` |
| ControlParameter, DuplicateMethodCall, FeatureEnvy, ManualDispatch, NilCheck, RepeatedConditional, UnusedParameters, UtilityFunction | Both `application_cable` files; `controllers/relationships_controller.rb`; `controllers/sessions_controller.rb`; `helpers/users_helper.rb`; `models/user.rb` |
| SubclassedFromCoreClass | Both `application_cable` files; `controllers/application_controller.rb`; `jobs/application_job.rb`; `mailers/application_mailer.rb`; `models/application_record.rb` |
| NestedIterators | Both `application_cable` files; `controllers/account_activations_controller.rb`, `application_controller.rb`, `microposts_controller.rb`, `password_resets_controller.rb`, `relationships_controller.rb`, `sessions_controller.rb`, `static_pages_controller.rb`, `users_controller.rb`; `helpers/application_helper.rb`, `sessions_helper.rb`, `users_helper.rb`; `mailers/user_mailer.rb`; `models/user.rb` |
| TooManyStatements | Both `application_cable` files; `controllers/account_activations_controller.rb`, `application_controller.rb`, `microposts_controller.rb`, `password_resets_controller.rb`, `sessions_controller.rb`, `static_pages_controller.rb`, `users_controller.rb`; `helpers/application_helper.rb`, `sessions_helper.rb`; `models/user.rb` |
| UnusedPrivateMethod | Both `application_cable` files; `controllers/application_controller.rb`, `microposts_controller.rb`, `password_resets_controller.rb`, `relationships_controller.rb`, `users_controller.rb`; `helpers/account_activations_helper.rb`, `application_helper.rb`, `microposts_helper.rb`, `password_resets_helper.rb`, `relationships_helper.rb`, `sessions_helper.rb`, `static_pages_helper.rb`, `users_helper.rb`; the opt-in process crashes on the `application_job.rb` shape. |

## Follow-ups and stop condition

The already-published follow-up tickets map directly to the remaining result groups: [97](../../.scratch/fleek/issues/97-rails-flay-completion-gate.md) Flay; [98](../../.scratch/fleek/issues/98-rails-reek-object-scopes.md) object scopes; [99](../../.scratch/fleek/issues/99-rails-reek-method-api.md) method API; [100](../../.scratch/fleek/issues/100-rails-reek-calls-and-flow.md) calls and flow; [101](../../.scratch/fleek/issues/101-rails-reek-data-size-and-names.md) data, size and names. The previously untracked opt-in crash has its own minimal child, [127](../../.scratch/fleek/issues/127-unused-private-method-framework-subclass-crash.md). No mismatch was silently classified as complete. Parent ticket 24 and final gate 102 remain open.
