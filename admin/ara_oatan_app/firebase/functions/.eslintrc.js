module.exports = {
  env: {
    es6: true,
    node: true,
  },
  extends: ["eslint:recommended"],
  parserOptions: {
    ecmaVersion: 2020,
  },
  rules: {
    "no-console": "off",
    "no-constant-condition": "off",
  },
};
