- # =============================================================================
# RULE 1: DIGESTIBLE PR RULE
# =============================================================================
echo "### 📋 RULE 1: DIGESTIBLE PR RULE" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/551ccf7208a1dcf3f3edd27cac002214" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Size Classification (Production Code Only):**" >> "$OUTPUT_FILE"
echo "- XS: <50 lines | S: 50-100 lines | M: 100-200 lines | L: 200+ lines" >> "$OUTPUT_FILE"
echo "- **Action Required:** If PR is >M size, recommend breaking into smaller, focused PRs" >> "$OUTPUT_FILE"
echo "- **Focus:** Each PR should have single, clear purpose and pass tests independently" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 2: CLASS NAMING CONVENTION
# =============================================================================
echo "### 🏗️ RULE 2: CLASS NAMING CONVENTION" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/89f05e4f83e087f63148bbbb1d99a178" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Patterns:**" >> "$OUTPUT_FILE"
echo "- **UseCase:** \`VerbNounUseCase\` (single business operation)" >> "$OUTPUT_FILE"
echo "- **Service:** \`NounService\` (complex domain logic)" >> "$OUTPUT_FILE"
echo "- **Manager:** \`NounManager\` (stateful coordination)" >> "$OUTPUT_FILE"
echo "- **Repository:** \`NounRepository\` (data access abstraction)" >> "$OUTPUT_FILE"
echo "- **DataSource:** \`Local/RemoteNounDataSource\` (raw data handling)" >> "$OUTPUT_FILE"
echo "- **Helper Layer:** \`Noun(Formatter|Validator|Parser|Mapper|Converter)\`. **FORBIDDEN:** \`Helper\`, \`Util\` suffixes." >> "$OUTPUT_FILE"
echo "- **BLoC:** \`NounBloc\` + \`NounEvent\` + \`NounState\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:** Verify all new classes follow naming conventions and layer responsibilities" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 3: TEST DOUBLE PATTERN
# =============================================================================
echo "### 🧪 RULE 3: TEST DOUBLE PATTERN" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/89687b7414f62a8c042b16b52e9ceb0b" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Test real integration between components, only fake external dependencies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Rules:**" >> "$OUTPUT_FILE"
echo "- ❌ **Avoid:** Fake everything approach (only fakes, no real implementations)" >> "$OUTPUT_FILE"
echo "- ✅ **Use:** Test Double pattern (real A + real B + fake external dependencies)" >> "$OUTPUT_FILE"
echo "- 🔒 **Forbidden:** Mock & Stub usage" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**When Testing Class A → Class B:**" >> "$OUTPUT_FILE"
echo "- Use **real implementation of B**" >> "$OUTPUT_FILE"
echo "- Swap out **B's external dependencies** with fakes (DB, Network, 3P libraries)" >> "$OUTPUT_FILE"
echo "- Test **real integration** and **real business logic**" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify tests use real implementations for business logic components" >> "$OUTPUT_FILE"
echo "- Check that only external dependencies (DB, network, 3P) are faked" >> "$OUTPUT_FILE"
echo "- Ensure BLoCs test real UseCases, UseCases test real Services, etc." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 4: COREUI COMPONENTS USAGE
# =============================================================================
echo "### 🎨 RULE 4: COREUI COMPONENTS USAGE" >> "$OUTPUT_FILE"
echo "**Core Principle:** All UI components, styling, and design tokens must use CoreUI package instead of Flutter's default Material components" >> "$OUTPUT_FILE"
echo "**Core Principle:** For the latest CoreUI theme tokens and design system details, use the CoreUI README:
https://github.com/ripplearc/coreui#readme" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Requirements:**" >> "$OUTPUT_FILE"
echo "- ✅ **Spacing:** Use \`CoreSpacing\` (e.g., \`CoreSpacing.space16\`) instead of hardcoded values like \`EdgeInsets.all(24.0)\` or \`SizedBox(height: 24)\`" >> "$OUTPUT_FILE"
echo "- ✅ **Icons:** Use \`CoreIcons\` and \`CoreIconWidget\` instead of \`Icons.*\` from Material" >> "$OUTPUT_FILE"
echo "- ✅ **Typography:** Use \`CoreTypography\` (e.g., \`CoreTypography.bodyMediumRegular()\`) instead of \`TextStyle\` with hardcoded font properties" >> "$OUTPUT_FILE"
echo "- ✅ **Colors:** Use \`CoreTextColors\`, \`CoreBackgroundColors\`, and other CoreUI color classes instead of \`Colors.*\` or \`Theme.of(context).*\` for colors" >> "$OUTPUT_FILE"
echo "- ✅ **Components:** Use CoreUI components (e.g., \`CoreButton\`, \`CoreTextField\`) instead of Material equivalents (\`ElevatedButton\`, \`TextFormField\`)" >> "$OUTPUT_FILE"
echo "- ✅ **Theme:** Use \`CoreTheme\` for theme configuration" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify all spacing values use \`CoreSpacing\` constants" >> "$OUTPUT_FILE"
echo "- Check that icons use \`CoreIcons\` and \`CoreIconWidget\`" >> "$OUTPUT_FILE"
echo "- Ensure typography uses \`CoreTypography\` methods" >> "$OUTPUT_FILE"
echo "- Confirm colors come from CoreUI color classes, not Material \`Colors\` or theme lookups" >> "$OUTPUT_FILE"
echo "- Validate that UI components use CoreUI equivalents (e.g., \`CoreButton\` not \`ElevatedButton\`)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 5: UI & BUSINESS LOGIC SEPARATION
# =============================================================================
echo "### 🎨 RULE 5: UI & BUSINESS LOGIC SEPARATION" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines and code samples, search: https://gist.github.com/ripplearcgit/f190fecc8f7124e511cb01283f9fbc31" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Keep the UI 'dumb.' It should only handle layout, user input, and reflecting state." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Red Flags (Business Logic Pollution):**" >> "$OUTPUT_FILE"
echo "- ❌ **Guard Checks in UI:** Validating domain rules (e.g., 'is userId null?') before sending an event to the BLoC." >> "$OUTPUT_FILE"
echo "- ❌ **State Duplication:** Using \`setState\` to copy data from a BLoC/Repository into the Widget's local variables." >> "$OUTPUT_FILE"
echo "- ❌ **Manual Coordination:** Using one BLoC's listener to manually trigger an event in a different BLoC." >> "$OUTPUT_FILE"
echo "- ❌ **Transformation Logic:** Formatting raw data (dates, currency) or mapping errors to strings inside the Widget." >> "$OUTPUT_FILE"
echo "- ❌ **Navigation Decisions:** Deciding which route to take based on business conditions inside the UI." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Ensure the UI only dispatches 'Intents' (Events) and consumes 'States'." >> "$OUTPUT_FILE"
echo "- Verify that all validation, data fetching, and coordination live in BLoCs or UseCases." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 6: STREAM-BASED PERFORMANCE & LIFECYCLE
# =============================================================================
echo "### ⚡ RULE 6: STREAM-BASED PERFORMANCE & LIFECYCLE" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines and code samples, search: https://gist.github.com/ripplearcgit/7818b412bf5fbe06269e0c3830e136f5" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Manage stream lifecycles strictly to prevent memory leaks and minimize redundant network/CPU overhead." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Red Flags (Performance Risks):**" >> "$OUTPUT_FILE"
echo "- ❌ **Zombies:** Storing \`StreamControllers\` in a Map without using \`onCancel\` to close and remove them when listeners are gone." >> "$OUTPUT_FILE"
echo "- ❌ **Network Thrashing:** Triggering a full network re-fetch (e.g., \`getEstimations\`) every time a stream-based write occurs." >> "$OUTPUT_FILE"
echo "- ❌ **Event Flooding:** Forcing UI rebuilds on every stream tick without using \`distinct()\` or \`debounceTime()\` for high-frequency data." >> "$OUTPUT_FILE"
echo "- ❌ **Dangling Subscriptions:** Creating manual listeners in BLoCs or Services without cancelling them in the \`close()\` or \`dispose()\` method." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify that all \`StreamControllers\` have a clear cleanup strategy." >> "$OUTPUT_FILE"
echo "- Check for 'Optimistic UI' patterns where local state is updated instead of a full server re-fetch." >> "$OUTPUT_FILE"
echo "- Ensure all BLoC stream subscriptions are cancelled during disposal." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 7: SELF-DOCUMENTING & CLEAN CODE (ANTI-AI ARTIFACTS)
# =============================================================================
echo "### 🧹 RULE 7: SELF-DOCUMENTING & CLEAN CODE" >> "$OUTPUT_FILE"
echo "**Core Principle:** Code must be expressive and clean. Use 'Code Documentation' to define contracts, but avoid 'Implementation Comments' to explain logic." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**✅ What to Keep (Code Documentation):**" >> "$OUTPUT_FILE"
echo "- **Public APIs:** Brief docstrings for Classes, Interfaces, and public Methods that explain *purpose* and *usage*." >> "$OUTPUT_FILE"
echo "- **Member Variables:** Documentation explaining the *intent* of a state variable if not immediately obvious." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**❌ Red Flags (Implementation Comments/Vibe Killers):**" >> "$OUTPUT_FILE"
echo "- **AI Residuals:** Instructional comments left by LLMs like \`// <-- ADD THIS\`, \`// implementation here\`, or \`// Fix: ...\`." >> "$OUTPUT_FILE"
echo "- **Step-by-Step Narratives:** Comments inside methods explaining *what* each line does. If the logic is complex, extract it into a named private method instead." >> "$OUTPUT_FILE"
echo "- **Obscure Naming:** Using generic names (\`data\`, \`info\`, \`val\`) that force a comment to explain what the variable actually holds." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- **Purge AI Artifacts:** Delete all instructional placeholders or AI-suggested annotations." >> "$OUTPUT_FILE"
echo "- **Refactor vs. Explain:** If you feel the urge to write a comment inside a function, refactor that logic into a descriptive variable or helper method instead." >> "$OUTPUT_FILE"
echo "- **Maintain Contracts:** Ensure docstrings accurately reflect the *behavior* of the code without detailing the *implementation*." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 8: WIDGET TEST BEHAVIOR & ROBUST FIND EXPRESSIONS
# =============================================================================
echo "### 🧪 RULE 8: WIDGET TEST BEHAVIOR & ROBUST FIND EXPRESSIONS" >> "$OUTPUT_FILE"
echo "**Core Principle:** Widget tests should focus on behavior, not implementation details. Use Keys for reliable widget finding." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Test Behavior, Not Implementation:**" >> "$OUTPUT_FILE"
echo "- ✅ **Focus on:** What the widget does (user interactions, displayed content, state changes)" >> "$OUTPUT_FILE"
echo "- ❌ **Avoid:** Testing implementation details (specific widget types, internal structure, exact widget counts)" >> "$OUTPUT_FILE"
echo "- ✅ **Example Good:** Test that tapping a button triggers a callback or navigates" >> "$OUTPUT_FILE"
echo "- ❌ **Example Bad:** Test that a widget tree contains exactly 3 \`CoreIconWidget\` instances" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Robust Find Expressions:**" >> "$OUTPUT_FILE"
echo "- ❌ **Forbidden:** Fragile find expressions that rely on implementation details:" >> "$OUTPUT_FILE"
echo "  - \`expect(find.byType(CoreIconWidget), findsNWidgets(3))\` - breaks if widget structure changes" >> "$OUTPUT_FILE"
echo "  - \`find.byType(IconButton).first\` - fragile, order-dependent" >> "$OUTPUT_FILE"
echo "  - \`find.byType(Row)\` - too generic, may match unintended widgets" >> "$OUTPUT_FILE"
echo "- ✅ **Preferred:** Use Keys for reliable, semantic widget finding:" >> "$OUTPUT_FILE"
echo "  - \`find.byKey(const Key('auth_footer_link'))\` - semantic, stable" >> "$OUTPUT_FILE"
echo "  - \`find.byKey(Key('pin_input'))\` - clear intent, resilient to refactoring" >> "$OUTPUT_FILE"
echo "- ✅ **Acceptable:** Text-based finds when testing user-visible content:" >> "$OUTPUT_FILE"
echo "  - \`find.text('Logout')\` - tests visible content" >> "$OUTPUT_FILE"
echo "  - \`find.widgetWithText(CoreButton, 'Continue')\` - semantic and user-focused" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify tests focus on behavior and user interactions, not implementation details" >> "$OUTPUT_FILE"
echo "- Check that find expressions use Keys for widget identification" >> "$OUTPUT_FILE"
echo "- Ensure no tests use \`findsNWidgets\` with \`byType\` for implementation-specific widgets" >> "$OUTPUT_FILE"
echo "- Confirm that widget finding is semantic and resilient to refactoring" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 9: UNIT TESTS — BEHAVIOR OVER IMPLEMENTATION
# =============================================================================
echo "### 🧪 RULE 9: UNIT TESTS — BEHAVIOR OVER IMPLEMENTATION" >> "$OUTPUT_FILE"
echo "**Core Principle:** Unit tests (BLoC, Service, Repository, UseCase) should assert observable behavior and outputs, not internal structure." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Test Behavior, Not Implementation:**" >> "$OUTPUT_FILE"
echo "- ✅ **Focus on:** Public API outputs, emitted states, returned values, side-effects at boundaries" >> "$OUTPUT_FILE"
echo "- ❌ **Avoid:** Internal method calls, private state, internal data structures" >> "$OUTPUT_FILE"
echo "- ✅ **Example Good:** Service returns expected domain model for a given input" >> "$OUTPUT_FILE"
echo "- ❌ **Example Bad:** Asserting a private internal helper method was called" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify unit tests assert observable behavior and outputs and have good coverage" >> "$OUTPUT_FILE"
echo "- Ensure refactors that keep behavior intact do not break tests" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 10: LOCALIZATION USAGE
# =============================================================================
echo "### 🌐 RULE 10: LOCALIZATION USAGE" >> "$OUTPUT_FILE"
echo "**Core Principle:** All user-facing strings must be localized using \`AppLocalizations\` instead of hardcoded strings" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Requirements:**" >> "$OUTPUT_FILE"
echo "- ✅ **User-Facing Text:** All strings displayed to users must use \`AppLocalizations\`" >> "$OUTPUT_FILE"
echo "- ✅ **Access Methods:** Use \`AppLocalizations.of(context)\` or \`LocalizationMixin\`'s \`l10n\` property" >> "$OUTPUT_FILE"
echo "- ❌ **Forbidden:** Hardcoded strings in \`Text\` widgets, button labels, titles, error messages shown to users" >> "$OUTPUT_FILE"
echo "- ✅ **Acceptable:** Technical/debug strings, log messages, internal identifiers, test strings" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Examples:**" >> "$OUTPUT_FILE"
echo "- ❌ **Bad:** \`Text('Welcome back')\` - hardcoded string" >> "$OUTPUT_FILE"
echo "- ✅ **Good:** \`Text(AppLocalizations.of(context)?.welcomeMessage ?? '')\`" >> "$OUTPUT_FILE"
echo "- ❌ **Bad:** \`label: 'Logout'\` - hardcoded label" >> "$OUTPUT_FILE"
echo "- ✅ **Good:** \`label: '\${AppLocalizations.of(context)?.logoutButton}'\`" >> "$OUTPUT_FILE"
echo "- ❌ **Bad:** \`title: const Text('Construculator')\` - hardcoded title" >> "$OUTPUT_FILE"
echo "- ✅ **Good:** \`title: Text(AppLocalizations.of(context)?.appTitle ?? '')\`" >> "$OUTPUT_FILE"
echo "- ✅ **Good (with mixin):** \`Text(l10n?.welcomeMessage ?? '')\` - using \`LocalizationMixin\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify all user-facing strings use \`AppLocalizations\`" >> "$OUTPUT_FILE"
echo "- Check that \`Text\` widgets, button labels, titles, and error messages are localized" >> "$OUTPUT_FILE"
echo "- Ensure no hardcoded English strings appear in UI code" >> "$OUTPUT_FILE"
echo "- Confirm that localization keys exist in \`app_en.arb\` for all new strings" >> "$OUTPUT_FILE"
echo "- Validate proper null-safety handling (use \`?? ''\` or \`?.property\` with null checks)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 11: PRECISION VS. ABSTRACTION (LEVEL-BASED NAMING)
# =============================================================================
echo "### 🏷️ RULE 11: PRECISION VS. ABSTRACTION (LEVEL-BASED NAMING)" >> "$OUTPUT_FILE"
echo "**Core Principle:** Naming precision must be inversely proportional to the abstraction level. The lower the level (Data/Repo), the more explicit the name; the higher the level (UI/UseCase), the more abstract the name." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**The Abstraction Scale:**" >> "$OUTPUT_FILE"
echo "1. **High Level (UI/Domain):** Focus on 'What'. Use abstract terms (e.g., \`getEstimations\`)." >> "$OUTPUT_FILE"
echo "2. **Low Level (Repository/Data Source):** Focus on 'How' and 'Scope'. Use explicit terms (e.g., \`fetchInitialProjectEstimations\`)." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Requirements:**" >> "$OUTPUT_FILE"
echo "- ✅ **Avoid Ambiguity at the Bottom:** Repository methods must explicitly state if they perform network fetches, handle pagination resets, or have 'get-or-create' side effects." >> "$OUTPUT_FILE"
echo "- ✅ **Contract Clarity:** Ensure lower-level names include the lookup key (e.g., \`ByProjectId\`) and the operation type (fetch, find, ensure)." >> "$OUTPUT_FILE"
echo "- ❌ **Hidden Logic:** Never hide initialization or state-reset logic behind a generic 'get' name in the Data Layer." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Examples:**" >> "$OUTPUT_FILE"
echo "- ❌ **Bad (Data Layer):** \`getEstimations(id)\` — Is it from cache? Does it reset pagination? Does it create a project if missing?" >> "$OUTPUT_FILE"
echo "- ✅ **Good (Data Layer):** \`fetchInitialEstimationsByProjectId(id)\` — Clearly defines the source (fetch), the intent (initial/reset), and the scope (by ID)." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Audit [cost_estimation_repository.dart](https://github.com/ripplearc/construculator-app/tree/main443) and its [implementation](url?id=9873) for ambiguous names." >> "$OUTPUT_FILE"
echo "- Rename methods that perform complex logic (like resetting pagination) to reflect their full impact." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"


# =============================================================================
# RULE 12: CLEAN PRESENTATION & STATE DERIVATION
# =============================================================================
echo "### 🏗️ RULE 12: CLEAN PRESENTATION & STATE DERIVATION" >> "$OUTPUT_FILE"
echo "**Core Principle:** UI components should be 'Passive Viewers.' They may decide *how* to present data, but must not derive *new meaning* from it. If a value requires business rules, cross-state coordination, or non-trivial computation, it belongs in the BLoC or a Usecase." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Red Flags (Logic Contamination):**" >> "$OUTPUT_FILE"
echo "- ❌ **Derived Value Calculation:** Performing math or logic that reshapes or reinterprets state data (e.g., \`itemCount: base + (loading ? 1 : 0)\`)." >> "$OUTPUT_FILE"
echo "- ❌ **Index Manipulation:** Manually adjusting indices to 'fit' data into a layout (e.g., \`data[index - 1]\`)." >> "$OUTPUT_FILE"
echo "- ❌ **Cross-State Coordination:** Writing logic that compares multiple BLoC states to derive a single UI result." >> "$OUTPUT_FILE"
echo "- ❌ **Complex Conditionals:** Using nested ternary operators or long if-else chains to decide which widget to render." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**✅ Preferred Patterns:**" >> "$OUTPUT_FILE"
echo "- **Composed UI Models:** The BLoC should emit a state specifically shaped for the UI, where structural decisions (like loading placeholders or separators) are already resolved." >> "$OUTPUT_FILE"
echo "- **Structural Separation:** Use layout-native solutions (like \`Slivers\`, \`Column\` children, or \`Stack\`) to handle optional elements instead of forcing them into a single dynamic builder." >> "$OUTPUT_FILE"
echo "- **View Helpers:** If logic is strictly visual and does not reinterpret or combine state sources, extract it into descriptive getters or private methods to keep the \`build\` method declarative." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Flag any UI code performing arithmetic (\`+\`, \`-\`, \`*\`) or coordinating between multiple state sources to derive meaning." >> "$OUTPUT_FILE"
echo "- Suggest moving derived or coordinated state into the BLoC's \`mapEventToState\` logic or a dedicated UI Mapper." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 13: MUTATION TESTING FOR LOGIC-HEAVY CHANGES
# =============================================================================
echo "### 🧬 RULE 13: MUTATION TESTING FOR LOGIC-HEAVY CHANGES" >> "$OUTPUT_FILE"
echo "**Core Principle:** PRs that introduce or modify complex business logic, mathematical calculations, or data transformations (e.g., pagination, filtering) must be validated with mutation testing on the affected logic files." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Requirements:**" >> "$OUTPUT_FILE"
echo "- ✅ **Threshold:** Achieve a mutation score of 80% or higher for the specific files modified." >> "$OUTPUT_FILE"
echo "- ✅ **Targeted execution:** Run mutation tests only on logic-heavy components (Repositories, DataSources, BLoCs, Usecases) to keep feedback cycles fast." >> "$OUTPUT_FILE"
echo "- ❌ **No Surviving Mutants in Critical Logic:** Any surviving mutant in boundary conditions or core decision paths indicates a missing or insufficient unit test." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Identify files with 'heavy logic' (e.g., \`cost_estimation_repository_impl.dart\`)." >> "$OUTPUT_FILE"
echo "- Verify mutation tests were run and surviving mutants were analyzed or eliminated in those files." >> "$OUTPUT_FILE"
echo "- Ensure unit tests are added to cover the gaps exposed by surviving mutants." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# GENERAL CODE REVIEW CRITERIA
# =============================================================================
echo "### 🔍 GENERAL CODE REVIEW CRITERIA" >> "$OUTPUT_FILE"
echo "1. 📝 Code quality and best practices" >> "$OUTPUT_FILE"
echo "2. 🐛 Potential bugs or edge cases" >> "$OUTPUT_FILE"
echo "3. ⚡ Performance implications" >> "$OUTPUT_FILE"
echo "4. 🔒 Security concerns" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"


# Don't run tests more than twice

# PREFER OBJECT COMPARISON INSTEAD OF COMPARING FIELDS
