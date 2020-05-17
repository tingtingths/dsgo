enum EventAction { ADD, REMOVE, UPDATE }

class ChangeEvent<T> {
  EventAction action;
  T value;

  ChangeEvent(this.action, this.value);
}
