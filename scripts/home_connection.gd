extends Node

signal updated(state: Dictionary)
signal problem(message: String)
signal connection_changed(connected: bool)

var base_url := "http://127.0.0.1:8787"
var identity := "a"
var connected := false
var cookie := ""
var busy := false
var last_state: Dictionary = {}
var _request := HTTPRequest.new()

func _ready() -> void:
	add_child(_request)
	_request.timeout = 8
	if OS.has_feature("web"):
		base_url=str(JavaScriptBridge.eval("window.location.origin"))
		call_deferred("_resume_browser_session")

func _resume_browser_session() -> void:
	await send("/api/home2d")

func login(address: String, code: String, id: String) -> void:
	if busy: return
	base_url = address.strip_edges().trim_suffix("/")
	if not (base_url.begins_with("http://") or base_url.begins_with("https://")):
		problem.emit("伺服器網址需以 http:// 或 https:// 開頭")
		return
	identity = id
	cookie = ""
	connected = false
	var ok := await send("/api/login", {"id":id,"code":code})
	if ok:
		if OS.has_feature("web"): cookie="browser-session"
		await send("/api/home2d")

func command(data: Dictionary) -> bool:
	if busy:
		problem.emit("正在同步，請稍後再試")
		return false
	return await send("/api/home2d",data)

func send(endpoint: String, data: Dictionary = {}) -> bool:
	if busy: return false
	busy = true
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not OS.has_feature("web") and not cookie.is_empty(): headers.append("Cookie: " + cookie)
	var method := HTTPClient.METHOD_GET if data.is_empty() else HTTPClient.METHOD_POST
	var error := _request.request(base_url+endpoint,headers,method,"" if data.is_empty() else JSON.stringify(data))
	if error != OK:
		busy=false
		problem.emit("無法發出連線請求")
		return false
	var result: Array = await _request.request_completed
	busy=false
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		connected=false
		connection_changed.emit(false)
		problem.emit("連線中斷，正在嘗試恢復；未送出的文字會保留")
		return false
	var parsed = JSON.parse_string(result[3].get_string_from_utf8())
	if result[1] != 200 or not parsed is Dictionary:
		if result[1] == 401:
			cookie=""
			connected=false
			connection_changed.emit(false)
		problem.emit(str(parsed.get("error","伺服器回應不正確")) if parsed is Dictionary else "伺服器回應不正確")
		return false
	for header in result[2]:
		if header.to_lower().begins_with("set-cookie:"):
			cookie=header.substr(11).strip_edges().split(";")[0]
	if endpoint == "/api/home2d":
		if OS.has_feature("web"):
			cookie="browser-session"
			identity=str(parsed.id)
		last_state=parsed
		connected=true
		connection_changed.emit(true)
		updated.emit(parsed)
	return true
