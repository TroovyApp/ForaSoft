import AbstractFieldsValidator from './AbstractFieldsValidator';

export default function validateLoginFields(fields, options) {
  return new LoginFieldsValidator(fields, options).validate();
}

class LoginFieldsValidator extends AbstractFieldsValidator {
  doCheckForSingleValue() {
    if (!this.fields.email)
      this.addError('email', 'Please enter an email');

    if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i.test(this.fields.email))
      this.addError('email', 'Please enter a valid email');

    if (!this.fields.password)
      this.addError('password', 'Please enter a password');
  }
}
