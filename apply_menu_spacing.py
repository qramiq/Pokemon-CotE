from pathlib import Path
p = Path('Test_Area.tscn')
s = p.read_text(encoding='utf-8')
for panel in ['TeamPanel', 'PokedexPanel', 'SavePanel', 'OptionsPanel']:
    marker = f'[node name="MarginContainer" type="MarginContainer" parent="MenuLayer/MainMenu/{panel}"'
    start = s.find(marker)
    if start == -1:
        continue
    prop_end = s.find('\n[node name=', start + len(marker))
    if prop_end == -1:
        prop_end = len(s)
    block = s[start:prop_end]
    if 'theme_override_constants/margin_left' not in block:
        block = block.replace('layout_mode = 2\n', 'layout_mode = 2\n' \
            'theme_override_constants/margin_left = 24\n' \
            'theme_override_constants/margin_top = 20\n' \
            'theme_override_constants/margin_right = 24\n' \
            'theme_override_constants/margin_bottom = 20\n', 1)
    s = s[:start] + block + s[prop_end:]
    vmarker = f'[node name="VBoxContainer" type="VBoxContainer" parent="MenuLayer/MainMenu/{panel}/MarginContainer"'
    vstart = s.find(vmarker)
    if vstart != -1:
        vend = s.find('\n[node name=', vstart + len(vmarker))
        if vend == -1:
            vend = len(s)
        vblock = s[vstart:vend]
        if 'theme_override_constants/separation' not in vblock:
            vblock = vblock.replace('layout_mode = 2\n', 'layout_mode = 2\ntheme_override_constants/separation = 8\n', 1)
        s = s[:vstart] + vblock + s[vend:]
# Ensure the main menu title uses the new light palette rather than the old black override.
s = s.replace('theme_override_colors/font_color = Color(0, 0, 0, 1)\ntheme_override_fonts/font = ExtResource("22_wx40u")\ntext = "POKÉMON-MENÜ"',
              'theme_override_colors/font_color = Color(1, 0.86, 0.46, 1)\ntheme_override_fonts/font = ExtResource("22_wx40u")\ntext = "POKÉMON-MENÜ"')
p.write_text(s, encoding='utf-8')
