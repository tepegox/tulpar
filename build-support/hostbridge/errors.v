module hostbridge
import hostvalue as ah
pub struct BindingError {
pub:
	value map[string]ah.Value
}

pub fn (e BindingError) msg() string { return ah.field(e.value, 'message').text() }

pub fn (e BindingError) code() int { return 0 }

pub struct PolicyError {
pub:
	kind    string
	message string
}

pub fn (e PolicyError) msg() string { return e.message }

pub fn (e PolicyError) code() int { return 0 }

pub struct PayloadError {
pub:
	message string
	cause   map[string]ah.Value
}

pub fn (e PayloadError) msg() string { return e.message }

pub fn (e PayloadError) code() int { return 0 }


pub fn failure(err IError) map[string]ah.Value {
 if err is BindingError { return err.value }
 if err is PolicyError { return {"kind": ah.Value(err.kind), "message": ah.Value(err.message)} }
 if err is PayloadError { return {"kind": ah.Value("RuntimeError"), "message": ah.Value(err.message), "cause": ah.Value(err.cause)} }
 for kind in ['OverflowError', 'IndexError', 'struct.error', 'ValueError', 'TypeError'] {
  prefix := kind + ': '
  if err.msg().starts_with(prefix) { return {'kind': ah.Value(kind), 'error': ah.Value(err.msg()[prefix.len..])} }
 }
 return {'kind': ah.Value('RuntimeError'), 'error': ah.Value(err.msg())}
}
