class StripeConfig {
  // REPLACE WITH YOUR ACTUAL VALUES
  static const String publishableKey = 'pk_test_51SDmUiClgG6ar97K5n5b7UaOuuzEgPvb9fSlRxj0e7IRfTfREJ9WO8Eir268ON7XbtRI2z5vXzOOK2VcV0eYeJi200HVbzI4Fd';
  static const String backendUrl = 'http://localhost:3000'; // Or your deployed URL
  
  // Add this to main.dart before runApp():
  // await Stripe.instance.applySettings(
  //   publishableKey: StripeConfig.publishableKey,
  // );
}