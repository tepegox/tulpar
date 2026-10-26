module resource
import stat
fn C.tulpar_stack_alloc(usize) voidptr
pub interface Resource {
mut:
 stat stat.Stat
}
