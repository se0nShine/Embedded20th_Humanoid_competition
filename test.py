def A(a):
    print('a', a)


def B(b):
    print('b', b)


dic = {'a': A, 'b': B}
dic['a'](5)
