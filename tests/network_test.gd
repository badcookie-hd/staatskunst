extends SceneTree
const Session = preload("res://scripts/session.gd")
var session
var failed = false

func _initialize():
	call_deferred("run")

func run():
	session = Session.new()
	session.name = "Session"
	root.add_child(session)
	if "--server" in OS.get_cmdline_user_args():
		session.solo(0, 2026 if "--modern" in OS.get_cmdline_user_args() else 1936)
		if session.host_game() != OK:
			printerr("NET FAIL: host creation"); quit(1); return
		await create_timer(8.0).timeout
		if session.sim.country(1).tax != 30:
			printerr("NET FAIL: authenticated client command not applied"); failed = true
		if session.sim.country(0).tax != 25:
			printerr("NET FAIL: client mutated host country"); failed = true
		if int(session.sim.state.day) != 0:
			printerr("NET FAIL: client advanced paused host"); failed = true
		print("NETWORK HOST: " + ("FAIL" if failed else "PASS"))
		session.disconnect_session()
		quit(1 if failed else 0)
	else:
		if session.join_game("127.0.0.1") != OK: quit(1); return
		await create_timer(2.0).timeout
		if session.player_id != 1 or session.players.size() != 2:
			printerr("NET FAIL: assignment or snapshot"); failed = true
		if session.sim.year() != (2026 if "--modern" in OS.get_cmdline_user_args() else 1936):
			printerr("NET FAIL: scenario not synchronized"); failed = true
		session.toggle_pause()
		session.command("tax_up")
		await create_timer(1.0).timeout
		if session.sim.country(1).tax != 30:
			printerr("NET FAIL: authoritative state did not sync"); failed = true
		session.command("campaign_99")
		await create_timer(1.0).timeout
		if session.sim.country(1).tax != 30 or session.running:
			printerr("NET FAIL: invalid command or pause authority"); failed = true
		print("NETWORK CLIENT: " + ("FAIL" if failed else "PASS"))
		session.disconnect_session()
		quit(1 if failed else 0)
