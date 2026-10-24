from pathlib import Path
p=Path('scripts/show_main.gd');s=p.read_text(encoding='utf-8')
s=s.replace('const HOLD_COIN', 'const GoldAmount = preload("res://scripts/gold_amount.gd")\nvar gold_amounts = {}\nvar gold_fonts = {}\nconst HOLD_COIN',1)
s=s.replace('func split_y():\n\treturn', 'func split_y():\n\tif modal_kind == "bonus" and game.bonus.flags[1]:\n\t\treturn 815\n\treturn',1)
s=s.replace('sprite.visible = modal_kind in ["", "bonus"]', 'sprite.visible = modal_kind == "" or (modal_kind == "bonus" and not game.bonus.flags[1])')
s=s.replace('func _draw():\n', 'func _draw():\n\tfor amount in gold_amounts.values():\n\t\tamount.visible = false\n',1)
s=s.replace('\t_draw_vault_fx()\n\tdraw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)\n\tvar b = game.bonus', '\tif not game.bonus.flags[1]:\n\t\t_draw_vault_fx()\n\tdraw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)\n\tvar b = game.bonus',1)
s=s.replace('\tbox(Rect2(42, 607, 940, 710), Color("230a0b"), gold, 20, 6)', '''\tvar start = 320 if double_grid else 607
\tif double_grid:
\t\tdraw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
\t\tbox(Rect2(42, 320, 940, 495), Color("230a0b"), gold, 20, 6)
\t\tdraw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)
\t\tbox(Rect2(42, 815, 940, 502), Color("230a0b"), gold, 20, 6)
\t\tdraw_set_transform(Vector2(0, STRIP), 0, Vector2.ONE)
\telse:
\t\tbox(Rect2(42, 607, 940, 710), Color("230a0b"), gold, 20, 6)''',1)
s=s.replace('Rect2(66, 614, 892, 65)', 'Rect2(66, start + 7, 892, 65)',1).replace('Rect2(80, 618, 864, 36)', 'Rect2(80, start + 11, 864, 36)',1).replace('Rect2(80, 653, 864, 23)', 'Rect2(80, start + 46, 864, 23)',1)
s=s.replace('"SUPER BÔNUS!" if b.flags.count(true) > 1', '"SUPER BÔNUS!" if double_grid or b.flags.count(true) > 1',1)
s=s.replace('\t\tvar y = 722 + panel * 274 if double_grid else 728\n\t\tvar rect = Rect2(70, y, 884, 224 if double_grid else 490)', '''\t\tvar offset = STRIP if double_grid and panel == 0 else off_bottom()
\t\tdraw_set_transform(Vector2(0, offset), 0, Vector2.ONE)
\t\tvar y = 430 + panel * 428 if double_grid else 728
\t\tvar rect = Rect2(70, y, 884, 360 if double_grid else 490)''',1)
a=s.index('\t\t\t\t\tvar caption = money(coin.value');e=s.index('\n\t\t\t\tif coin.multiplier',a)
s=s[:a]+'''\t\t\t\t\t_draw_coin_amount(r * 5 + col, money(coin.value * game.denomination), dest, offset)
'''.rstrip()+s[e:]
s=s.replace('\tbox(Rect2(70, 1234, 884, 65)', '\tdraw_set_transform(Vector2(0, off_bottom()), 0, Vector2.ONE)\n\tbox(Rect2(70, 1234, 884, 65)',1)
at=s.index('func _draw_falling_coin(')
s=s[:at]+'''func _draw_coin_amount(id, caption, dest, offset):
\tvar type_size = 40
\twhile type_size > 14 and font(type_size).get_string_size(caption).x > dest.size.x * 0.84 - 8:
\t\ttype_size -= 1
\tif not gold_fonts.has(type_size):
\t\tvar face = DynamicFont.new()
\t\tface.font_data = font(type_size).font_data
\t\tface.size = type_size
\t\tface.outline_size = 3
\t\tface.outline_color = Color("a21807")
\t\tgold_fonts[type_size] = face
\tif not gold_amounts.has(id):
\t\tvar amount = GoldAmount.new()
\t\tadd_child(amount)
\t\tgold_amounts[id] = amount
\tvar width = font(type_size).get_string_size(caption).x
\tvar at = dest.position + Vector2((dest.size.x - width) * 0.5, dest.size.y * 0.65 - type_size * 0.5)
\tgold_amounts[id].set_amount(caption, gold_fonts[type_size], at + Vector2(0, offset))

'''+s[at:]
p.write_text(s,encoding='utf-8')
