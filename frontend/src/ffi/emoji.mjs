export const flagFromCountryCode = (countryCode) => {
    return countryCode.replace(/./g, (char) =>
        String.fromCodePoint(0x1f1a5 + char.toUpperCase().charCodeAt())
    )
}