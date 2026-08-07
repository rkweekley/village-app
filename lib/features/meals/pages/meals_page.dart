import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/features/meals/meals_service.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class MealsPage extends ConsumerWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meals'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Week'),
              Tab(text: 'Recipes'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _WeekTab(),
            _RecipesTab(),
            _FavoritesTab(),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
const _mealIcons = {
  'Breakfast': Icons.free_breakfast,
  'Lunch': Icons.lunch_dining,
  'Dinner': Icons.dinner_dining,
  'Snack': Icons.cookie,
};

Color _difficultyColor(String d) {
  switch (d) {
    case 'Easy':
      return VillageTheme.positive;
    case 'Medium':
      return VillageTheme.warning;
    case 'Hard':
      return VillageTheme.danger;
    default:
      return Colors.grey;
  }
}

String _formatMinutes(int mins) {
  if (mins < 60) return '${mins}m';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}

String _formatIsoDate(String iso) {
  final d = DateTime.parse(iso);
  return '${d.month}/${d.day}';
}

// ── Week Tab ──

class _WeekTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends ConsumerState<_WeekTab> {
  late DateTime _weekStart;
  int _weekOffset = 0;
  int _selectedDayIndex = DateTime.now().weekday % 7;

  @override
  void initState() {
    super.initState();
    _weekStart = _computeWeekStart();
  }

  DateTime _computeWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  void _previousWeek() {
    setState(() {
      _weekOffset--;
      _weekStart = _computeWeekStart();
      _selectedDayIndex = 0;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekOffset++;
      _weekStart = _computeWeekStart();
      _selectedDayIndex = 0;
    });
  }

  String get _weekStartStr =>
      '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';

  List<DateTime> get _daysInWeek =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final mealPlansAsync = ref.watch(mealPlansListProvider(_weekStartStr));

    return Column(
      children: [
        // Week navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousWeek,
                style: IconButton.styleFrom(
                  backgroundColor: VillageTheme.surfaceBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'Week of ${_weekStart.month}/${_weekStart.day}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextWeek,
                style: IconButton.styleFrom(
                  backgroundColor: VillageTheme.surfaceBase,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Day strip (horizontal scrollable)
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 7,
            itemBuilder: (ctx, i) {
              final day = _daysInWeek[i];
              final isToday = day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;
              final isSelected = i == _selectedDayIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = i),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VillageTheme.danger
                        : isToday
                            ? VillageTheme.danger.withValues(alpha: 0.1)
                            : VillageTheme.surfaceBase,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: VillageTheme.danger.withValues(alpha: 0.3),
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Content for selected day
        Expanded(
          child: mealPlansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (mealPlans) {
              if (mealPlans.isEmpty) {
                return _EmptyWeekPlaceholder(
                  onCreateMealPlan: () async {
                    await ref
                        .read(mealsServiceProvider)
                        .createMealPlan(_weekStartStr);
                    ref.invalidate(mealPlansListProvider(_weekStartStr));
                  },
                );
              }
              final plan = mealPlans.first;
              final dayEntries = plan.entries
                  .where((e) => e.dayOfWeek == _selectedDayIndex)
                  .toList();

              return RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(mealPlansListProvider(_weekStartStr).future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Selected day header
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        '${_dayNames[_selectedDayIndex]} · ${_daysInWeek[_selectedDayIndex].month}/${_daysInWeek[_selectedDayIndex].day}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Meal slots for selected day
                    for (final mealType in _mealTypes) ...[
                      _MealSlot(
                        mealType: mealType,
                        entry: dayEntries
                            .where((e) => e.mealType == mealType)
                            .firstOrNull,
                        mealPlanId: plan.id,
                        dayOfWeek: _selectedDayIndex,
                        ref: ref,
                        onRefresh: () =>
                            ref.refresh(
                                mealPlansListProvider(_weekStartStr).future),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyWeekPlaceholder extends StatelessWidget {
  final VoidCallback onCreateMealPlan;
  const _EmptyWeekPlaceholder({required this.onCreateMealPlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: VillageTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.restaurant_rounded,
                size: 40, color: VillageTheme.danger),
          ),
          const SizedBox(height: 16),
          const Text('No meal plan for this week.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap below to create one',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Meal Plan'),
            onPressed: onCreateMealPlan,
            style: FilledButton.styleFrom(
              backgroundColor: VillageTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String mealType;
  final MealPlanEntry? entry;
  final String mealPlanId;
  final int dayOfWeek;
  final WidgetRef ref;
  final VoidCallback onRefresh;

  const _MealSlot({
    required this.mealType,
    this.entry,
    required this.mealPlanId,
    required this.dayOfWeek,
    required this.ref,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _mealIcons[mealType] ?? Icons.restaurant_rounded;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showMealSlotPicker(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: entry != null
              ? VillageTheme.danger.withValues(alpha: 0.08)
              : VillageTheme.surfaceBase,
          borderRadius: BorderRadius.circular(14),
          border: entry == null
              ? Border.all(color: Colors.grey.withValues(alpha: 0.15))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry != null
                    ? VillageTheme.danger.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: entry != null
                    ? VillageTheme.danger
                    : Colors.grey[500],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry != null
                        ? (entry!.recipeTitle ?? entry!.title ?? 'Tap to edit')
                        : 'Tap to add',
                    style: TextStyle(
                      fontWeight: entry != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                      color: entry != null ? null : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (entry != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.grey[400],
                onPressed: () async {
                  await ref
                      .read(mealsServiceProvider)
                      .removeEntry(mealPlanId, entry!.id);
                  onRefresh();
                },
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  void _showMealSlotPicker(BuildContext context) async {
    // Pre-fetch recipes so they're ready when the modal opens
    final service = ref.read(mealsServiceProvider);
    final recipes = await service.getRecipes();

    if (!context.mounted) return;

    // Sheet-local state lives OUTSIDE the StatefulBuilder builder —
    // declared inside, it gets recreated on every rebuild (each keystroke
    // via setDialogState), which reset the controller and made the custom
    // title field impossible to type into.
    String? selectedRecipeId;
    String freeTextTitle = '';
    final titleCtrl = TextEditingController();

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VillageTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_mealIcons[mealType] ?? Icons.restaurant_rounded,
                          color: VillageTheme.danger, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Add $mealType',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Favorite recipes',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: Builder(
                    builder: (context) {
                      final favs =
                          recipes.where((r) => r.isFamilyFavorite).toList();
                      if (favs.isEmpty) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No favorites yet — star a recipe below',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: favs.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (_, i) {
                          final r = favs[i];
                          return RadioListTile<String>(
                            title: Text(r.title,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              '${r.difficulty} · ${_formatMinutes(r.prepTimeMinutes)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: r.id,
                            groupValue: selectedRecipeId,
                            dense: true,
                            activeColor: VillageTheme.danger,
                            onChanged: (v) => setDialogState(
                                () => selectedRecipeId = v),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                const Text('Or type a custom title:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Spaghetti Bolognese',
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    setDialogState(() {
                      freeTextTitle = v;
                      selectedRecipeId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (selectedRecipeId == null && freeTextTitle.isEmpty) return;
                    await ref.read(mealsServiceProvider).addEntry(
                          mealPlanId,
                          dayOfWeek: dayOfWeek,
                          mealType: mealType,
                          recipeId: selectedRecipeId,
                          title: selectedRecipeId != null ? null : freeTextTitle,
                        );
                    Navigator.pop(ctx);
                    onRefresh();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.danger,
                  ),
                  child: const Text('Add to Plan',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Recipe List Tile ──

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final WidgetRef ref;
  final VoidCallback onRefresh;

  const _RecipeCard({
    required this.recipe,
    required this.ref,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final diffColor = _difficultyColor(r.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      color: VillageTheme.surfaceCard,
      child: InkWell(
        onTap: () => _showRecipeDetailSheet(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading color block
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.menu_book_rounded,
                      color: diffColor, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            r.isFamilyFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: r.isFamilyFavorite
                                ? VillageTheme.warning
                                : Colors.grey[300],
                            size: 22,
                          ),
                          onPressed: () async {
                            await ref
                                .read(mealsServiceProvider)
                                .toggleFavorite(r.id);
                            onRefresh();
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.difficulty,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: diffColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Prep time
                        Icon(Icons.schedule_rounded,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          _formatMinutes(r.prepTimeMinutes),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        // Servings
                        Icon(Icons.people_rounded,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          '${r.servings}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (r.tags != null && r.tags!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        r.tags!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipeDetailSheet(BuildContext context) {
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final r = recipe;
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          r.isFamilyFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: r.isFamilyFavorite
                              ? VillageTheme.warning
                              : Colors.grey[400],
                          size: 28,
                        ),
                        onPressed: () async {
                          await ref
                              .read(mealsServiceProvider)
                              .toggleFavorite(r.id);
                          setDialogState(() {});
                          onRefresh();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Meta badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _metaChip(r.difficulty, Icons.flag_rounded,
                          _difficultyColor(r.difficulty)),
                      _metaChip(_formatMinutes(r.prepTimeMinutes),
                          Icons.schedule_rounded, Colors.grey),
                      _metaChip('${r.servings} servings', Icons.people_rounded,
                          Colors.grey),
                    ],
                  ),
                  if (r.tags != null && r.tags!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(r.tags!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],

                  // Description
                  if (r.description != null && r.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(r.description!,
                        style: const TextStyle(color: Colors.grey)),
                  ],

                  const SizedBox(height: 20),
                  // Ingredients
                  const Text('Ingredients',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 8),
                  ...r.ingredients
                      .split(',')
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .map((ingredient) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 7, right: 10),
                                  decoration: BoxDecoration(
                                    color: VillageTheme.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 14))),
                              ],
                            ),
                          )),
                  const SizedBox(height: 20),

                  // Instructions
                  const Text('Instructions',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 8),
                  ...r.instructions
                      .split(RegExp(r'[,.\\n]+'))
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: VillageTheme.danger
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: VillageTheme.danger,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(entry.value,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          )),

                  const SizedBox(height: 24),

                  // Add to meal plan button
                  FilledButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add to Meal Plan'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddToMealPlanSheet(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: VillageTheme.danger,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metaChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  void _showAddToMealPlanSheet(BuildContext context) {
    String? selectedPlanId;
    int selectedDay = DateTime.now().weekday % 7;
    String selectedMealType = 'Dinner';

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final mealPlansAsync = ref.watch(mealPlansListProvider(null));

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: VillageTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: VillageTheme.danger, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add to Meal Plan',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                mealPlansAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (plans) {
                    if (plans.isEmpty) {
                      return const Center(
                        child: EmptyState(
                          icon: Icons.calendar_month_rounded,
                          title: 'No meal plans yet',
                          subtitle: 'Create one from the Week tab first',
                          iconBgColor: VillageTheme.danger,
                          iconColor: VillageTheme.danger,
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedPlanId,
                          decoration: InputDecoration(
                            labelText: 'Meal Plan',
                            filled: true,
                            fillColor: VillageTheme.surfaceBase,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: plans
                              .map((p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                        'Week of ${_formatIsoDate(p.weekStart)}'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedPlanId = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedDay,
                                decoration: InputDecoration(
                                  labelText: 'Day',
                                  filled: true,
                                  fillColor: VillageTheme.surfaceBase,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: List.generate(
                                    7,
                                    (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(_dayNames[i]),
                                        )),
                                onChanged: (v) => setDialogState(
                                    () => selectedDay = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedMealType,
                                decoration: InputDecoration(
                                  labelText: 'Meal',
                                  filled: true,
                                  fillColor: VillageTheme.surfaceBase,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _mealTypes
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (v) => setDialogState(
                                    () => selectedMealType = v!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (selectedPlanId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a meal plan.')),
                      );
                      return;
                    }
                    try {
                      await ref.read(mealsServiceProvider).addEntry(
                            selectedPlanId!,
                            dayOfWeek: selectedDay,
                            mealType: selectedMealType,
                            recipeId: recipe.id,
                            title: recipe.title,
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added ${recipe.title} to ${_dayNames[selectedDay]} $selectedMealType'),
                          ),
                        );
                        onRefresh();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.danger,
                  ),
                  child: const Text('Add to Plan',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Create Recipe Sheet ──

void _showCreateRecipeSheet(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final ingredientsCtrl = TextEditingController();
  final instructionsCtrl = TextEditingController();
  final prepCtrl = TextEditingController(text: '30');
  final servingsCtrl = TextEditingController(text: '4');
  String difficulty = 'Easy';
  final tagsCtrl = TextEditingController();
  bool isFamilyFavorite = false;

  showAdaptiveModalSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: VillageTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: VillageTheme.danger, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('New Recipe',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Recipe title',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredientsCtrl,
                decoration: InputDecoration(
                  labelText: 'Ingredients',
                  hintText: 'Comma-separated list',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsCtrl,
                decoration: InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Step-by-step instructions',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: prepCtrl,
                      decoration: InputDecoration(
                        labelText: 'Prep time (min)',
                        filled: true,
                        fillColor: VillageTheme.surfaceBase,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: servingsCtrl,
                      decoration: InputDecoration(
                        labelText: 'Servings',
                        filled: true,
                        fillColor: VillageTheme.surfaceBase,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: difficulty,
                decoration: InputDecoration(
                  labelText: 'Difficulty',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Easy', 'Medium', 'Hard']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setDialogState(() => difficulty = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsCtrl,
                decoration: InputDecoration(
                  labelText: 'Tags (optional)',
                  hintText: 'e.g. Italian, Quick, Vegetarian',
                  filled: true,
                  fillColor: VillageTheme.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Family favorite'),
                value: isFamilyFavorite,
                activeColor: VillageTheme.danger,
                onChanged: (v) =>
                    setDialogState(() => isFamilyFavorite = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  try {
                    await ref.read(mealsServiceProvider).createRecipe(
                          title: titleCtrl.text,
                          description: descCtrl.text.isNotEmpty
                              ? descCtrl.text
                              : null,
                          ingredients: ingredientsCtrl.text,
                          instructions: instructionsCtrl.text,
                          prepTimeMinutes:
                              int.tryParse(prepCtrl.text) ?? 30,
                          servings: int.tryParse(servingsCtrl.text) ?? 4,
                          difficulty: difficulty,
                          tags: tagsCtrl.text.isNotEmpty ? tagsCtrl.text : null,
                          isFamilyFavorite: isFamilyFavorite,
                        );
                    ref.invalidate(recipesListProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Failed: $e'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: VillageTheme.danger,
                ),
                child: const Text('Create Recipe',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Recipes Tab ──

class _RecipesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends ConsumerState<_RecipesTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _difficultyFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          // Difficulty filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _filterChip('All', _difficultyFilter == null, () {
                  setState(() => _difficultyFilter = null);
                }),
                const SizedBox(width: 8),
                _filterChip('Easy', _difficultyFilter == 'Easy', () {
                  setState(() => _difficultyFilter = 'Easy');
                }),
                const SizedBox(width: 8),
                _filterChip('Medium', _difficultyFilter == 'Medium', () {
                  setState(() => _difficultyFilter = 'Medium');
                }),
                const SizedBox(width: 8),
                _filterChip('Hard', _difficultyFilter == 'Hard', () {
                  setState(() => _difficultyFilter = 'Hard');
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Recipe cards
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (recipes) {
                var filtered = recipes;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((r) =>
                          r.title.toLowerCase().contains(_searchQuery) ||
                          (r.tags?.toLowerCase().contains(_searchQuery) ??
                              false))
                      .toList();
                }
                if (_difficultyFilter != null) {
                  filtered = filtered
                      .where((r) => r.difficulty == _difficultyFilter)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'No recipes found',
                    subtitle: 'Try adjusting your filters',
                    iconBgColor: VillageTheme.danger,
                    iconColor: VillageTheme.danger,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(recipesListProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _RecipeCard(
                      recipe: filtered[i],
                      ref: ref,
                      onRefresh: () =>
                          ref.refresh(recipesListProvider.future),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRecipeSheet(context, ref),
        backgroundColor: VillageTheme.danger,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? VillageTheme.danger
              : VillageTheme.surfaceBase,
          borderRadius: BorderRadius.circular(10),
          border: !selected
              ? Border.all(color: Colors.grey.withValues(alpha: 0.2))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ── Favorites Tab ──

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(familyFavoritesListProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (recipes) {
        if (recipes.isEmpty) {
          return const EmptyState(
            icon: Icons.star_rounded,
            title: 'No favorite recipes yet',
            subtitle: 'Star a recipe to add it here',
            iconBgColor: VillageTheme.warning,
            iconColor: VillageTheme.warning,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(familyFavoritesListProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: recipes.length,
            itemBuilder: (ctx, i) => _RecipeCard(
              recipe: recipes[i],
              ref: ref,
              onRefresh: () =>
                  ref.refresh(familyFavoritesListProvider.future),
            ),
          ),
        );
      },
    );
  }
}
