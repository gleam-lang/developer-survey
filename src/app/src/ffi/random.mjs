export const int = (min, max) => {
    return float(min, max) | 0
}

export const float = (min, max) => {
    return min + Math.random() * (max - min)
}