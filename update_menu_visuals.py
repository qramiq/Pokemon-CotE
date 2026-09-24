from pathlib import Path

p = Path('Test_Area.tscn')
s = p.read_text(encoding='utf-8')

# Add the reusable theme resource.
needle = '[ext_resource type="Script" uid="uid://cxeyy6mlh05ej" path="res://options.gd" id="27_pbxft"]\n'
insert = needle + '[ext_resource type="Theme" path="res://menu_theme.tres" id="39_theme"]\n'
if 'res://menu_theme.tres' not in s:
    s = s.replace(needle, insert)

# Theme and font inheritance for the complete menu layer.
s = s.replace('[node name="MainMenu" type="Control" parent="MenuLayer" unique_id=2137093851]\n',
              '[node name="MainMenu" type="Control" parent="MenuLayer" unique_id=2137093851]\n'
              'theme = ExtResource("39_theme")\n'
              'theme_override_fonts/font = ExtResource("22_wx40u")\n')

# Dark translucent overlay instead of the previous placeholder gray.
s = s.replace('color = Color(18.892157, 18.892157, 18.892157, 1)',
              'color = Color(0.008, 0.016, 0.045, 0.82)')

# Right-side menu card: compact, readable and consistent with the submenu cards.
s = s.replace('offset_left = 981.0\noffset_top = 75.0\noffset_right = 1138.0\noffset_bottom = 283.0',
              'offset_left = 820.0\noffset_top = 54.0\noffset_right = 1138.0\noffset_bottom = 470.0')
s = s.replace('[node name="MainMenuContent" type="VBoxContainer" parent="MenuLayer/MainMenu/MenuPanel" unique_id=1765648830]\nlayout_mode = 2',
              '[node name="MainMenuContent" type="VBoxContainer" parent="MenuLayer/MainMenu/MenuPanel" unique_id=1765648830]\nlayout_mode = 2\ntheme_override_constants/separation = 7')
s = s.replace('text = "Menü"', 'text = "POKÉMON-MENÜ"', 1)
s = s.replace('text = "Beutel"', 'text = "▸  BEUTEL"', 1)
s = s.replace('text = "Party"', 'text = "▸  PARTY"', 1)
s = s.replace('text = "Pokedex"', 'text = "▸  POKÉDEX"', 1)
s = s.replace('text = "Speichern"', 'text = "▸  SPEICHERN"', 1)
s = s.replace('text = "Optionen"', 'text = "▸  OPTIONEN"', 1)
s = s.replace('text = "Schließen"', 'text = "×  SCHLIESSEN"', 1)

# Make all submenu panels use the same card bounds.
for panel in ['BagPanel', 'TeamPanel', 'PokedexPanel', 'SavePanel', 'OptionsPanel']:
    start = s.find(f'[node name="{panel}" type="PanelContainer"')
    if start < 0:
        continue
    end = s.find('\n[node name=', start + 10)
    if end < 0:
        end = len(s)
    block = s[start:end]
    block = block.replace('layout_mode = 1\nanchors_preset = -1\nanchor_right = 2.8500001\nanchor_bottom = 5.3750005\noffset_bottom = -1.5258789e-05',
                          'layout_mode = 0\noffset_left = 390.0\noffset_top = 54.0\noffset_right = 1138.0\noffset_bottom = 470.0')
    block = block.replace('layout_mode = 1\nanchors_preset = -1\nanchor_right = 3.2500002\nanchor_bottom = 4.925\noffset_right = -1.5258789e-05',
                          'layout_mode = 0\noffset_left = 390.0\noffset_top = 54.0\noffset_right = 1138.0\noffset_bottom = 470.0')
    block = block.replace('layout_mode = 0\noffset_right = 40.0\noffset_bottom = 40.0',
                          'layout_mode = 0\noffset_left = 390.0\noffset_top = 54.0\noffset_right = 1138.0\noffset_bottom = 470.0')
    s = s[:start] + block + s[end:]

# Add padding and spacing to every submenu's root margin/vbox where present.
s = s.replace('type="MarginContainer" parent="MenuLayer/MainMenu/BagPanel"',
              'type="MarginContainer" parent="MenuLayer/MainMenu/BagPanel"\n')
# Apply safe, local replacements to the standard containers.
s = s.replace('theme_override_fonts/font = ExtResource("22_wx40u")\ntext = "Beutel"',
              'theme_override_fonts/font = ExtResource("22_wx40u")\n\ntext = "BEUTEL"')
s = s.replace('theme_override_fonts/font = ExtResource("22_wx40u")\ntext = "Team"',
              'theme_override_fonts/font = ExtResource("22_wx40u")\n\ntext = "TEAM"')
s = s.replace('theme_override_fonts/font = ExtResource("22_wx40u")\ntext = "Pokedex"',
              'theme_override_fonts/font = ExtResource("22_wx40u")\n\ntext = "POKÉDEX"')

p.write_text(s, encoding='utf-8')
