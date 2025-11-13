# Keydex Design Guide (keydex2 Theme)

## Design Philosophy

**Keywords**: Terminal-adjacent, ledger vibes, flat, confident typography, subtle grids/stripes

The keydex2 theme emphasizes a **professional, utilitarian aesthetic** with a muted, neutral palette inspired by ledgers and terminal interfaces. The design is deliberately restrained, with a single bold accent (orange) reserved exclusively for primary actions.

---

## Color Palette

### Primary Colors
- **Orange** `#DC714E` - **EXCLUSIVE to RowButton** (primary action buttons at bottom of screen)
  - Text on orange: `#FDFFF0` (cream)
  - This is the only place orange appears in the UI
  
- **Navy-Ink** `#243036` - Primary UI elements (ElevatedButton, other prominent elements)
- **Umber** `#7A4A2F` - Secondary actions (OutlinedButton, secondary UI)

### Background & Surface
- **Background** `#c1c4b1` - Main scaffold background (warm, muted sage)
- **Surface** `#c1c4b1` - Cards, forms, list tiles match background
- **Surface Container** `#464D41` - Chips, icons, subtle accents

### Text
- **Primary Text** `#21271C` - Main body text, headings
- **Secondary Text** `#676f62` - Subtitles, labels, helper text
- **Label Text** `rgba(103, 111, 98, 0.6)` - Form field labels (60% opacity)
- **Focused Border** `#7F8571` - Form field border when focused

### System Colors
- **Error** `#D95C5C`
- **Success** Green accents for confirmations

---

## Typography

### Font Families
- **Body Text**: OpenSans - Clean, readable, professional
- **Titles/Headings**: Archivo - Confident, strong presence
- **Monospace**: RobotoMono - For technical content, keys, addresses

### Type Scale
```
displaySmall:   28pt, Archivo, weight 700
headlineSmall:  22pt, Archivo, weight 500
titleLarge:     22pt, Archivo, weight 600
bodyLarge:      14pt, OpenSans, weight 500
bodyMedium:     14pt, OpenSans, weight 400
labelSmall:     12pt, OpenSans, weight 500
```

### AppBar Typography
- **Size**: 40pt
- **Weight**: 500 (medium)
- **Font**: Archivo
- **Alignment**: Left (not centered)
- **Height**: 100pt toolbar
- **Title Spacing**: 32pt
- **Leading Width**: 32pt

---

## Visual Style

### Shapes & Rounding
- **Minimal Rounding**: Flat, utilitarian aesthetic
  - **Form fields**: 4pt border radius
  - **Cards**: 4pt border radius
  - **Buttons**: 12pt border radius
  - **List items**: 0pt (no rounding, edge-to-edge)

### Elevation & Borders
- **Cards**: 0 elevation, no borders
- **List Tiles**: No borders, no elevation, extend edge-to-edge
- **Form Fields**: YES borders (subtle outline)
- **Buttons**: No borders unless explicitly an OutlinedButton

### Spacing
- Generous vertical spacing between sections
- Standard padding: 16pt
- Large titles create significant visual hierarchy

---

## Component Patterns

### RowButton (Primary Actions)
**Usage**: Single primary action at bottom of screen
- **Background**: Orange `#DC714E`
- **Text**: Cream `#FDFFF0`
- **Full width**, fixed at bottom
- **Icon + Text** format
- **Height**: 56pt minimum

**Example**: "Create Vault", "Save", main screen actions

### RowButtonStack (Multiple Actions)
**Usage**: Multiple actions at bottom of screen
- **Gradient**: Lighter colors at top → Orange at bottom
- Base color: `#474d42` (dark olive-sage)
- Progressively lighter going up
- Bottom button: Always orange
- Fixed at bottom of screen

**When to use**: 
- 2+ actions needed (e.g., Edit, Settings, Create)
- Actions are contextual to current screen
- Primary action is most important (goes at bottom in orange)

### Buttons (Non-Primary)
**ElevatedButton**: Navy-Ink `#243036` background
- For secondary elevated actions
- Used sparingly

**OutlinedButton**: Umber `#7A4A2F` border and text
- For secondary outline actions
- "Add Manually", "Cancel", alternative actions

**TextButton**: Navy-Ink `#243036` text
- For tertiary/minimal actions
- Dialog actions, inline actions

### Form Fields
- **Background**: Match scaffold `#c1c4b1`
- **Border**: Yes, subtle outline `#9AA38F`
- **Focused Border**: `#7F8571`, 1.5pt width
- **Label**: Archivo font, 60% opacity
- **Filled**: Yes (subtle background)
- **Border Radius**: 4pt

### List Items
- **Background**: Match scaffold
- **No borders**
- **No elevation**
- **No cards** wrapping them
- **Edge-to-edge**: Extend to screen edges
- **Icon background**: `#464D41` (surface container)
- **Icon color**: Match scaffold background
- **Text color**: Primary text `#21271C`
- **Subtitle color**: Secondary text `#676f62`

### Cards
- **Background**: Match scaffold `#c1c4b1`
- **Border**: None
- **Elevation**: 0
- **Border Radius**: 4pt
- **Margin**: As needed, not edge-to-edge
- **Use**: For grouping form sections, settings panels

---

## Layout Patterns

### Screen Structure
```
┌─────────────────────────┐
│ AppBar (large, left)    │ ← 100pt tall, 40pt text
├─────────────────────────┤
│                         │
│   Scrollable Content    │ ← Main content area
│                         │
│   [Cards, Lists, etc]   │
│                         │
├─────────────────────────┤
│   RowButton(Stack)      │ ← Fixed at bottom
└─────────────────────────┘
```

### Content Padding
- **Screen edges**: 16pt horizontal padding
- **Between sections**: 16pt vertical spacing
- **Within cards**: 16pt padding

### AppBar Style
- **Background**: Match scaffold `#c1c4b1`
- **Text**: Primary text `#21271C`
- **centerTitle**: false (always left-aligned)
- **No elevation**

---

## Color Usage Rules

### The Orange Rule
**Orange `#DC714E` appears ONLY on RowButton components.**
- Do NOT use orange for:
  - Regular buttons
  - Highlights
  - Borders
  - Icons
  - Text
  - Links

### When Orange Appears Multiple Times
Use **RowButtonStack** with gradient:
- Only the bottom-most button is orange
- Buttons above use progressively lighter shades of `#474d42`
- Creates clear visual hierarchy with orange at bottom

### Neutral-First Design
- Default to Navy-Ink and Umber for UI elements
- Muted, professional palette
- Orange stands out because it's rare

---

## Common Patterns

### Screen with Primary Action
```dart
Scaffold(
  appBar: AppBar(title: Text('Large Title')),
  body: Column(
    children: [
      Expanded(child: SingleChildScrollView(...)),
      RowButton(
        onPressed: () {},
        icon: Icons.add,
        text: 'Primary Action',
      ),
    ],
  ),
)
```

### Screen with Multiple Actions
```dart
// Bottom of screen
RowButtonStack(
  buttons: [
    RowButtonConfig(/* secondary */),
    RowButtonConfig(/* secondary */),
    RowButtonConfig(/* primary - will be orange */),
  ],
)
```

### Form Section
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section Title', 
          style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Field Label',
            hintText: 'Hint text',
          ),
        ),
      ],
    ),
  ),
)
```

### List of Items
```dart
// No Card wrapper, no padding
ListView.builder(
  itemBuilder: (context, index) => ListTile(
    leading: _buildIcon(),
    title: Text('Item title'),
    subtitle: Text('Item subtitle'),
    trailing: Icon(Icons.chevron_right),
  ),
)
```

---

## Design Inspirations

- **Ledgers**: Professional, structured, minimal decoration
- **Terminal UIs**: Confident typography, functional over decorative
- **Flat Design**: No unnecessary shadows or gradients
- **Brutalist Web**: Honest materials, clear hierarchy

---

## Things to Avoid

- ❌ Using orange anywhere except RowButton
- ❌ Excessive rounding (keep it minimal: 4pt or 12pt)
- ❌ Borders on list items
- ❌ Cards wrapping individual list items
- ❌ Centered AppBar titles
- ❌ Overly colorful UI elements
- ❌ Unnecessary elevation/shadows
- ❌ Small or timid typography

---

## Future Considerations

- **Subtle grids/stripes**: Could be added as background textures
- **Monospace elements**: Could be emphasized more for technical content
- **Dark mode**: Invert the palette while keeping the same philosophy

---

## Quick Reference Card

| Element | Color | Font | Size |
|---------|-------|------|------|
| Primary Action | Orange `#DC714E` | OpenSans | 56pt height |
| AppBar Title | Navy `#21271C` | Archivo | 40pt / 500 |
| Body Text | Navy `#21271C` | OpenSans | 14pt |
| Background | Sage `#c1c4b1` | - | - |
| Form Border | Sage-gray `#9AA38F` | - | 1pt |
| Focused Border | Sage-gray `#7F8571` | - | 1.5pt |
| Secondary Button | Umber `#7A4A2F` | OpenSans | - |

---

**Remember**: The design is intentionally restrained. Orange is special because it's rare. Neutrals create calm. Typography does the heavy lifting.

