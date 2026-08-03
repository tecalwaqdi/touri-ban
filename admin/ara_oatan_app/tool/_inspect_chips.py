# -*- coding: utf-8 -*-
from pathlib import Path

t = Path("lib/app/list_vi/list_vi_widget.dart").read_text(encoding="utf-8")
i = t.find("'0gjhqz6e'")
print("idx", i)
print(repr(t[i - 150 : i + 200]))
