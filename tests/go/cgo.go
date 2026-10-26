package main

/*
static int tulpar_add(int left, int right) {
	return left + right;
}
*/
import "C"

import "fmt"

func main() {
	if got := int(C.tulpar_add(19, 23)); got != 42 {
		panic(fmt.Sprintf("cgo returned %d, want 42", got))
	}
	fmt.Println("TULPAR CGO SMOKE PASS")
}
