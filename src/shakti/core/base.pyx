cdef class AsyncBase:
    ''' Allows multiple ways of using async class

        Example
            >>> class File(AsyncBase):
            ...
            ...     def __init__(self, path):
            ...         self.path = path
            ...
            ...     async def __ainit__(self):
            ...         await self.open()
            ...
            ...     async def open(self):
            ...         await async_open(self.path)

            # usage-1
            >>> file = await File(...)
            >>> await file.close()

            # usage-2 - `__ainit__` method is not called
            >>> file = File(...)
            >>> await file.open()
            >>> await file.close()

            # usage-3
            >>> async with File(...) as file:
            ...     ...

            # usage-4
            >>> async with Client() as (client, addr):
            ...     ...
    '''
    async def __ainit__(self):
        ''' `__ainit__` method must be created

            Note
                `__ainit__` method is called while using as:
                    ``await AsyncBase()``
                            # or
                    ``async with AsyncBase():``
        '''
        cdef unicode msg
        msg = self.__class__.__name__
        msg = f'`{msg}()` - user must implement `async def __ainit__(self)` method'
        raise NotImplementedError(msg)

    # midsync
    def __await__(self):
        return self.__aenter__().__await__()
        # note: `__await__` is called while `await AsyncBase()`

    async def __aenter__(self):
        if self.__awaited__:
            return self
        r = await self.__ainit__()
        self.__awaited__ = True
        return self if r is None else r

    async def __aexit__(self, *errors):
        if any(errors):
            return False

    def __enter__(self):
        cdef str name = self.__class__.__name__
        raise SyntaxError(f'`with {name}() ...` used, should be `async with {name}() ...`')

    def __exit__(self):
        cdef str name = self.__class__.__name__
        raise RuntimeError(f'`{name}()` - use of `__exit__` is not supported, use `__aexit__`')
        # note: this exception does not get triggered normally but added it just
        #       in case user does some funny business.
