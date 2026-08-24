bool touryShouldBlockUnverifiedCustomer({required bool emailVerified}) {
  return !emailVerified;
}
