// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2026 Alexander Medvednikov
module smp

import limine

// Direct builds can omit the MP request; terminal images enable LIMINE_MP=1.
fn limine_response() &limine.LimineSMPResponse {
	return unsafe { nil }
}
