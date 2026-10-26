// SPDX-License-Identifier: GPL-2.0-or-later
module sessiondaemon

import userland.sessioncore
import userland.sessionipc

fn test_legacy_clock_migration_preserves_policy_and_server_and_custom_services() {
	mut daemon := SessionDaemon{}
	daemon.supervisor.count = 3
	for i, executable in ['/usr/bin/tulpar-desktop', '/opt/custom-clock', '/usr/bin/tulpar-desktop-gpu'] {
		mut service := sessioncore.Service{
			name:          sessioncore.text(if i == 2 { 'custom-service' } else { 'clock-sync' })!
			executable:    sessioncore.text(executable)!
			enabled:       false
			restart:       .always
			restart_limit: 9
		}
		service.arguments[0].set('--time-service')!
		service.arguments[1].set('--time-server=192.0.2.1')!
		service.argument_count = 2
		daemon.supervisor.services[i] = service
	}
	custom := daemon.supervisor.services[1]
	other := daemon.supervisor.services[2]
	daemon.migrate_clock_service()
	clock := daemon.supervisor.services[0]
	path := sessionipc.helper_path('tulpar-timesync')
	defer { unsafe { path.free() } }
	assert clock.executable.str() == path
	assert !clock.enabled && clock.restart == .always && clock.restart_limit == 9
	assert clock.argument_count == 1 && clock.arguments[0].str() == '--time-server=192.0.2.1'
	assert daemon.supervisor.services[1] == custom && daemon.supervisor.services[2] == other
	daemon.migrate_clock_service()
	assert daemon.supervisor.services[0] == clock
}
