module.exports = {
    verbose: true,
    preset: "jest-playwright-preset",
    transform: {
        '^.+\\.js$': 'babel-jest',
        '\\.(jpg|jpeg|png|gif|webp|svg)$': 'jest-transform-file'
    }
};
