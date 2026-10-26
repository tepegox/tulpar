// SPDX-License-Identifier: GPL-2.0-or-later
module packagestore

import hostvalue as ah

fn git_files(root string) !string {
	command := collection('list', [literal(ah.Value('git'))!, literal(ah.Value('-C'))!,
		call('os.fspath', o(root))!, literal(ah.Value('ls-files'))!, literal(ah.Value('--cached'))!,
		literal(ah.Value('--others'))!, literal(ah.Value('--exclude-standard'))!,
		literal(ah.Value('-z'))!])!
	result := invoke('subprocess.run', [o(command)], {
		'check':  v(ah.Value(true))
		'stdout': o(call('subprocess.PIPE')!)
		'stderr': o(call('subprocess.PIPE')!)
	}) or {
		if kind(err, 'os_error') || kind(err, 'called_process') {
			failed('SourceSnapshotError', 'cannot enumerate host worktree: ' + err.msg(), err)!
		}
		return err
	}
	pieces := method(attribute(result, 'stdout')!, 'split', [b('00')], {})!
	iter := iterator(pieces)!
	mut files := []string{}
	for {
		row := next(iter)!
		if row.done { break }
		if truth(row.value)! { files << call('Path', o(call('os.fsdecode', o(row.value))!))! }
	}
	return collection('list', files)!
}

fn extra_files(root string, relative string) !string {
	extra := call('operator.truediv', o(root), o(relative))!
	if !truth(method(extra, 'is_dir', [], {})!)! {
		failed('SourceSnapshotError', 'host source extra is missing: ' + text(relative)!, none)!
	}
	if truth(method(join(extra, '.git')!, 'exists', [], {})!)! {
		files := call('git_worktree_files', o(extra))!
		iter := iterator(files)!
		mut out := []string{}
		for {
			row := next(iter)!
			if row.done { break }
			out << call('operator.truediv', o(relative), o(row.value))!
		}
		return collection('list', out)!
	}
	walk := call('os.walk', o(extra))!
	iter := iterator(walk)!
	mut files := []string{}
	for {
		row := next(iter)!
		if row.done { break }
		directory := call('operator.getitem', o(row.value), v(ah.Value(0)))!
		names := call('operator.getitem', o(row.value), v(ah.Value(1)))!
		filenames := call('operator.getitem', o(row.value), v(ah.Value(2)))!
		ni := iterator(names)!
		mut kept := []string{}
		for {
			n := next(ni)!
			if n.done { break }
			if !compare('eq', n.value, literal(ah.Value('.git'))!)! { kept << n.value }
		}
		whole := call('builtins.slice', o(null()!))!
		call('operator.setitem', o(names), o(whole), o(collection('list', kept)!))!
		base := call('Path', o(directory))!
		fi := iterator(filenames)!
		for {
			f := next(fi)!
			if f.done { break }
			joined := call('operator.truediv', o(base), o(f.value))!
			files << method(joined, 'relative_to', [o(root)], {})!
		}
	}
	return collection('list', files)!
}

fn stage_desktop(_root string, _ui2 string, destination string) ! {
 method(destination, "mkdir", [], {"parents": v(ah.Value(true)), "exist_ok": v(ah.Value(true))})!
}

fn normalize(member string) !string {
	for name in ['mtime', 'uid', 'gid'] { set_attr(member, name, v(ah.Value(0)))! }
	for name in ['uname', 'gname'] { set_attr(member, name, v(ah.Value('')))! }
	return member
}

fn source_snapshot(root string, extras string, ui2_arg string) !string {
	relative := call('git_worktree_files', o(root))!
	ei := iterator(extras)!
	for {
		row := next(ei)!
		if row.done { break }
		method(relative, 'extend', [o(call('extra_worktree_files', o(root), o(row.value))!)], {})!
	}
	ui2 := if truth(ui2_arg)! { ui2_arg } else { join(root, 'third_party/ui2')! }
	snapshot := invoke('tempfile.SpooledTemporaryFile', [], {
		'max_size': v(ah.Value(32 * 1024 * 1024))
	})!
	own(snapshot, 'close')!
	snapshot_archive(root, relative, ui2, snapshot) or {
		failure := err
		if kind(failure, 'os_error') || kind(failure, 'value_error') || kind(failure, 'tar_error') || kind(failure, 'source') {
			close(snapshot, failure)!
			if kind(failure, 'source') { return failure }
			failed('SourceSnapshotError', 'cannot archive host worktree: ' + failure.msg(), failure)!
		}
		transfer(snapshot)!
		return failure
	}
	transfer(snapshot)!
	return snapshot
}

fn snapshot_archive(root string, relative string, ui2 string, snapshot string) ! {
	manager := invoke('tempfile.TemporaryDirectory', [], {
		'prefix': v(ah.Value('tulpar-desktop-stage.'))
	})!
	temporary := enter(manager)!
	snapshot_temporary(root, relative, ui2, snapshot, temporary) or {
		failure := err
		if !retire(manager, failure)! { return failure }
		method(snapshot, 'seek', [v(ah.Value(0))], {})!
		return
	}
	retire(manager, none)!
	method(snapshot, 'seek', [v(ah.Value(0))], {})!
}

fn snapshot_temporary(root string, relative string, ui2 string, snapshot string, temporary string) ! {
	staged := join(call('Path', o(temporary))!, 'materialized')!
	snapshot_staged(root, relative, ui2, snapshot, staged)!
}

fn snapshot_staged(root string, relative string, ui2 string, snapshot string, staged string) ! {
	call('stage_desktop_sources', o(root), o(ui2), o(staged))!
	manager := invoke('tarfile.open', [], {
		'fileobj':     o(snapshot)
		'mode':        v(ah.Value('w:'))
		'format':      o(call('tarfile.USTAR_FORMAT')!)
		'dereference': v(ah.Value(false))
	})!
	archive := enter(manager)!
	snapshot_members(root, relative, staged, archive) or {
		failure := err
		if retire(manager, failure)! { return }
		return failure
	}
	retire(manager, none)!
}

fn snapshot_members(root string, relative string, staged string, archive string) ! {
	key := callback('resolve', {
		'name': ah.Value('os.fspath')
	})!.text()
	ordered := invoke('builtins.sorted', [o(call('builtins.set', o(relative))!)], {
		'key': o(key)
	})!
	iter := iterator(ordered)!
	for {
		row := next(iter)!
		if row.done { break }
		file := row.value
		if truth(method(file, 'is_absolute', [], {})!)! || truth(call('operator.contains', o(attribute(file, 'parts')!), v(ah.Value('..')))!)! {
			failed('SourceSnapshotError', 'unsafe host source path: ' + text(file)!, none)!
		}
		source := call('operator.truediv', o(root), o(file))!
		add_source(source, file, archive) or { if !kind(err, 'missing') { return err } }
	}
	filter := callback('resolve', {
		'name': ah.Value('normalize_staged_member')
	})!.text()
	method(archive, 'add', [o(staged)], {
		'arcname':   v(ah.Value('.tulpar-build'))
		'recursive': v(ah.Value(true))
		'filter':    o(filter)
	})!
}

fn add_source(source string, relative string, archive string) ! {
	if !truth(method(source, 'is_file', [], {})!)! && !truth(method(source, 'is_symlink', [], {})!)! {
		return
	}
	size := attribute(method(source, 'lstat', [], {})!, 'st_size')!
	if compare('gt', size, call('MAX_SHARED_FILE_BYTES')!)! {
		log('qemu-package-store: not sharing ' + text(relative)! + ' (' + text(size)! + ' bytes)')!
		return
	}
	method(archive, 'add', [o(source)], {
		'arcname':   o(method(relative, 'as_posix', [], {})!)
		'recursive': v(ah.Value(false))
	})!
}
