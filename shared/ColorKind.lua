return {
    BEGIN = 1,
    WHITE = 1,
    RED = 2,
    GREEN = 3,
    BLUE = 4,
    YELLOW = 5,
    MAGENTA = 6,
    CYAN = 7,
    END = 7,

    LOOKUP = {
        {1, 1, 1, 1},
        {1, 0, 0, 1},
        {0, 1, 0, 1},
        {0, 0, 1, 1},
        {1, 1, 0, 1},
        {1, 0, 1, 1},
        {0, 1, 1, 1},
    }
}
