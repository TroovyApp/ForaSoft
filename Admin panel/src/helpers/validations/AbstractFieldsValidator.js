export default class AbstractFieldsValidator {
  constructor(fields, options = {}) {
    this.errors = {};
    this.fields = fields;
    this.options = options;
  }

  validate() {
    this.doCheckForSingleValue();
    this.doCheckForRelations();
    return this.errors;
  }

  doCheckForSingleValue() {

  }

  addError(fieldKey, error) {
    this.errors[fieldKey] = this.errors[fieldKey] || error;
  }

  doCheckForRelations() {

  }
}
