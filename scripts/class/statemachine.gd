var stack = []
func init(initstate):
	stack.resize(1)
	stack[0] = initstate
	
func push(state):
	stack.push_front(state)

func pop():
	if stack.size() < 2:
		return
	stack.pop_front()

func getcurrentstate():
	return stack[0]