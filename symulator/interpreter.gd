class_name PyInterpreter
extends RefCounted

var vars := {}
var commands := []
var error := ""
var drone_cmds := {
	"takeoff": 0, "land": 0,
	"up": 1, "down": 1, "forward": 1, "back": 1, "left": 1, "right": 1,
	"cw": 1, "ccw": 1, "go": 4, "curve": 7, "set_speed": 1
}
const MAX_STEPS = 100000
var step_count = 0

func run(source: String) -> Dictionary:
	vars = {}
	commands = []
	error = ""
	step_count = 0
	var lines = source.split("\n")
	var prog = []
	for raw in lines:
		var s = raw
		var hp = _find_comment(s)
		if hp != -1:
			s = s.substr(0, hp)
		var stripped = s.strip_edges()
		if stripped.is_empty():
			continue
		if stripped.begins_with("from ") or stripped.begins_with("import ") or stripped.contains("Tello()"):
			continue
		prog.append({"indent": _indent(raw), "text": stripped})
	_exec_block(prog, 0, prog.size(), 0)
	return {"commands": commands, "error": error}

func _find_comment(line: String) -> int:
	var in_str = false
	var q = ""
	for i in line.length():
		var c = line[i]
		if in_str:
			if c == q: in_str = false
		else:
			if c == "\"" or c == "'":
				in_str = true; q = c
			elif c == "#":
				return i
	return -1

func _indent(line: String) -> int:
	var n = 0
	for c in line:
		if c == " ": n += 1
		elif c == "\t": n += 4
		else: break
	return n

func _exec_block(prog: Array, start: int, end: int, base_indent: int):
	var i = start
	while i < end:
		if error != "": return
		step_count += 1
		if step_count > MAX_STEPS:
			error = "Przekroczono limit kroków (możliwa nieskończona pętla)"
			return
		var line = prog[i]
		if line.indent < base_indent: return
		var text = line.text

		# --- for ---
		if text.begins_with("for "):
			var re = RegEx.new()
			re.compile("^for\\s+(\\w+)\\s+in\\s+(.+):$")
			var m = re.search(text)
			if m == null:
				error = "Błędna pętla for: " + text
				return
			var loop_var = m.get_string(1)
			var iter_expr = m.get_string(2).strip_edges()
			var iterable = _eval(iter_expr)
			if error != "": return
			var body_end = _block_end(prog, i + 1, end, line.indent)
			if not (iterable is Array):
				error = "for: oczekiwano listy/range"
				return
			for item in iterable:
				vars[loop_var] = item
				_exec_block(prog, i + 1, body_end, line.indent + 1)
				if error != "": return
			i = body_end
			continue

		# --- while ---
		if text.begins_with("while "):
			var cond_expr = text.substr(6, text.length() - 7).strip_edges()
			var body_end = _block_end(prog, i + 1, end, line.indent)
			while true:
				var cond = _eval(cond_expr)
				if error != "": return
				if not _truthy(cond): break
				_exec_block(prog, i + 1, body_end, line.indent + 1)
				if error != "": return
				step_count += 1
				if step_count > MAX_STEPS:
					error = "Przekroczono limit kroków (while)"
					return
			i = body_end
			continue

		# --- if / elif / else ---
		if text.begins_with("if "):
			var executed = false
			var j = i
			while j < end and prog[j].indent == line.indent:
				var t = prog[j].text
				var is_if = t.begins_with("if ")
				var is_elif = t.begins_with("elif ")
				var is_else = t.begins_with("else")
				if not (is_if or is_elif or is_else): break
				var body_end = _block_end(prog, j + 1, end, prog[j].indent)
				if not executed:
					var run_branch = false
					if is_else: run_branch = true
					else:
						var cond_str = t.substr(3 if is_if else 5, t.length() - (4 if is_if else 6)).strip_edges()
						var cond = _eval(cond_str)
						if error != "": return
						run_branch = _truthy(cond)
					if run_branch:
						_exec_block(prog, j + 1, body_end, prog[j].indent + 1)
						if error != "": return
						executed = true
				j = body_end
			i = j
			continue

		# --- wywołanie komendy drona ---
		var call_re = RegEx.new()
		call_re.compile("^(\\w+)\\.(\\w+)\\((.*)\\)$")
		var cm = call_re.search(text)
		if cm and cm.get_string(2) in drone_cmds:
			var method = cm.get_string(2)
			var arg_str = cm.get_string(3).strip_edges()
			var args = []
			if arg_str != "":
				for a in _split_args(arg_str):
					var v = _eval(a)
					if error != "": return
					args.append(int(round(_to_num(v))))
			if args.size() != drone_cmds[method]:
				error = "'%s' wymaga %d arg. (podano %d)" % [method, drone_cmds[method], args.size()]
				return
			var parts = [method]
			for a in args: parts.append(str(a))
			commands.append(" ".join(parts))
			i += 1
			continue

		# --- metoda listy ---
		var meth_re = RegEx.new()
		meth_re.compile("^(\\w+)\\.(\\w+)\\((.*)\\)$")
		var mm = meth_re.search(text)
		if mm:
			var obj_name = mm.get_string(1)
			var method = mm.get_string(2)
			var arg_str = mm.get_string(3).strip_edges()
			if vars.has(obj_name) and vars[obj_name] is Array:
				var arr = vars[obj_name]
				match method:
					"append": arr.append(_eval(arg_str))
					"pop": if arr.size() > 0: arr.pop_back()
					"remove": arr.erase(_eval(arg_str))
					_: error = "Nieznana metoda listy: " + method
				if error != "": return
				i += 1
				continue

		# --- przypisanie ---
		var eq = _top_level_assign(text)
		if eq != -1:
			var lhs = text.substr(0, eq).strip_edges()
			var rhs = text.substr(eq + 1).strip_edges()
			var val = _eval(rhs)
			if error != "": return
			var idx_re = RegEx.new()
			idx_re.compile("^(\\w+)\\[(.+)\\]$")
			var im = idx_re.search(lhs)
			if im:
				var arr_name = im.get_string(1)
				var idx = int(_to_num(_eval(im.get_string(2))))
				if vars.has(arr_name) and vars[arr_name] is Array:
					var arr = vars[arr_name]
					if idx >= 0 and idx < arr.size(): arr[idx] = val
					else: error = "Indeks poza zakresem: " + str(idx); return
				else: error = "Nie znaleziono listy: " + arr_name; return
			else: vars[lhs] = val
			i += 1
			continue

		error = "Błędna instrukcja: " + text
		return

func _block_end(prog: Array, start: int, end: int, parent_indent: int) -> int:
	var i = start
	while i < end:
		if prog[i].indent <= parent_indent: return i
		i += 1
	return end

func _top_level_assign(text: String) -> int:
	var depth = 0
	var in_str = false
	var q = ""
	for i in text.length():
		var c = text[i]
		if in_str:
			if c == q: in_str = false
			continue
		if c == "\"" or c == "'": in_str = true; q = c
		elif c == "(" or c == "[": depth += 1
		elif c == ")" or c == "]": depth -= 1
		elif c == "=" and depth == 0:
			var prev = text[i-1] if i > 0 else ""
			var nxt = text[i+1] if i+1 < text.length() else ""
			if prev in ["=", "<", ">", "!"] or nxt == "=": continue
			return i
	return -1

func _split_args(s: String) -> Array:
	var out = []
	var depth = 0
	var cur = ""
	var in_str = false
	var q = ""
	for c in s:
		if in_str:
			cur += c
			if c == q: in_str = false
			continue
		if c == "\"" or c == "'": in_str = true; q = c; cur += c
		elif c == "(" or c == "[": depth += 1; cur += c
		elif c == ")" or c == "]": depth -= 1; cur += c
		elif c == "," and depth == 0: out.append(cur.strip_edges()); cur = ""
		else: cur += c
	if cur.strip_edges() != "": out.append(cur.strip_edges())
	return out

func _truthy(v) -> bool:
	if v is bool: return v
	if v is float or v is int: return v != 0
	if v is Array: return v.size() > 0
	if v is String: return v != ""
	return v != null

func _to_num(v) -> float:
	if v is float: return v
	if v is int: return float(v)
	if v is bool: return 1.0 if v else 0.0
	return 0.0

var _toks := []
var _tp := 0

func _eval(expr: String):
	expr = expr.strip_edges()
	if expr == "": return null
	_toks = _tokenize(expr)
	_tp = 0
	return _parse_or()

func _tokenize(s: String) -> Array:
	var toks = []
	var i = 0
	var n = s.length()
	while i < n:
		var c = s[i]
		if c == " " or c == "\t": i += 1; continue
		if c == "\"" or c == "'":
			var q = c; var j = i + 1; var str_val = ""
			while j < n and s[j] != q: str_val += s[j]; j += 1
			toks.append({"t": "str", "v": str_val}); i = j + 1; continue
		if c.is_valid_int() or (c == "." and i+1 < n and s[i+1].is_valid_int()):
			var num = ""
			while i < n and (s[i].is_valid_int() or s[i] == "."): num += s[i]; i += 1
			toks.append({"t": "num", "v": num.to_float()}); continue
		if c.is_valid_identifier() or c == "_":
			var id = ""
			while i < n and (s[i].is_valid_identifier() or s[i] == "_" or s[i].is_valid_int()): id += s[i]; i += 1
			toks.append({"t": "id", "v": id}); continue
		var two = s.substr(i, 2)
		if two in ["==", "!=", "<=", ">=", "//"]:
			toks.append({"t": "op", "v": two}); i += 2; continue
		toks.append({"t": "op", "v": c}); i += 1
	return toks

func _peek(): return _toks[_tp] if _tp < _toks.size() else null
func _next(): var t = _peek(); _tp += 1; return t

func _parse_or():
	var left = _parse_and()
	while _peek() and _peek().t == "id" and _peek().v == "or":
		_next(); var right = _parse_and(); left = _truthy(left) or _truthy(right)
	return left

func _parse_and():
	var left = _parse_cmp()
	while _peek() and _peek().t == "id" and _peek().v == "and":
		_next(); var right = _parse_cmp(); left = _truthy(left) and _truthy(right)
	return left

func _parse_cmp():
	var left = _parse_add()
	while _peek() and _peek().t == "op" and _peek().v in ["==", "!=", "<", ">", "<=", ">="]:
		var op = _next().v; var right = _parse_add()
		match op:
			"==": left = (left == right)
			"!=": left = (left != right)
			"<": left = _to_num(left) < _to_num(right)
			">": left = _to_num(left) > _to_num(right)
			"<=": left = _to_num(left) <= _to_num(right)
			">=": left = _to_num(left) >= _to_num(right)
	return left

func _parse_add():
	var left = _parse_mul()
	while _peek() and _peek().t == "op" and _peek().v in ["+", "-"]:
		var op = _next().v; var right = _parse_mul()
		if op == "+": left = (left + right) if (left is Array and right is Array) else _to_num(left) + _to_num(right)
		else: left = _to_num(left) - _to_num(right)
	return left

func _parse_mul():
	var left = _parse_unary()
	while _peek() and _peek().t == "op" and _peek().v in ["*", "/", "//", "%"]:
		var op = _next().v; var right = _parse_unary()
		match op:
			"*": left = _to_num(left) * _to_num(right)
			"/": left = _to_num(left) / _to_num(right)
			"//": left = floor(_to_num(left) / _to_num(right))
			"%": left = fmod(_to_num(left), _to_num(right))
	return left

func _parse_unary():
	var t = _peek()
	if t and t.t == "op" and t.v == "-":
		_next(); return -_to_num(_parse_unary())
	if t and t.t == "id" and t.v == "not":
		_next(); return not _truthy(_parse_unary())
	return _parse_postfix()

func _parse_postfix():
	var val = _parse_primary()
	while _peek() and str(_peek().v) == "[":
		_next(); var idx = _parse_or()
		if _peek() and str(_peek().v) == "]": _next()
		if val is Array:
			var ii = int(_to_num(idx))
			if ii >= 0 and ii < val.size(): val = val[ii]
			else: error = "Indeks poza zakresem: " + str(ii); return null
	return val

func _parse_primary():
	var t = _peek()
	if t == null: return null
	if t.t == "num": _next(); return t.v
	if t.t == "str": _next(); return t.v
	if str(t.v) == "[":
		_next(); var arr = []
		if _peek() and str(_peek().v) != "]":
			arr.append(_parse_or())
			while _peek() and str(_peek().v) == ",": _next(); arr.append(_parse_or())
		if _peek() and str(_peek().v) == "]": _next()
		return arr
	if str(t.v) == "(":
		_next(); var inner = _parse_or()
		if _peek() and str(_peek().v) == ")": _next()
		return inner
	if t.t == "id":
		_next(); var name = t.v
		if _peek() and str(_peek().v) == "(":
			_next(); var fargs = []
			if _peek() and str(_peek().v) != ")":
				fargs.append(_parse_or())
				while _peek() and str(_peek().v) == ",": _next(); fargs.append(_parse_or())
			if _peek() and str(_peek().v) == ")": _next()
			return _call_builtin(name, fargs)
		if name == "True": return true
		if name == "False": return false
		if vars.has(name): return vars[name]
		error = "Nieznana zmienna: " + name; return null
	_next(); return null

func _call_builtin(name: String, args: Array):
	match name:
		"range":
			var arr = []
			if args.size() == 1: for k in range(int(_to_num(args[0]))): arr.append(float(k))
			elif args.size() == 2: for k in range(int(_to_num(args[0])), int(_to_num(args[1]))): arr.append(float(k))
			elif args.size() == 3:
				var step = int(_to_num(args[2])); var k = int(_to_num(args[0])); var stop = int(_to_num(args[1]))
				while (step > 0 and k < stop) or (step < 0 and k > stop): arr.append(float(k)); k += step
			return arr
		"len":
			if args.size() == 1 and args[0] is Array: return float(args[0].size())
			if args.size() == 1 and args[0] is String: return float(args[0].length())
			return 0.0
		"abs": return abs(_to_num(args[0]))
		"min": return _to_num(args[0]) if _to_num(args[0]) < _to_num(args[1]) else _to_num(args[1])
		"max": return _to_num(args[0]) if _to_num(args[0]) > _to_num(args[1]) else _to_num(args[1])
		_: error = "Nieznana funkcja: " + name; return null
