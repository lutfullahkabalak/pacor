<script setup lang="ts">
import { computed, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    modelValue: string
    length?: number
  }>(),
  { length: 4 },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
  complete: []
}>()

const inputRef = ref<HTMLInputElement | null>(null)
const isFocused = ref(false)

const digits = computed(() =>
  Array.from({ length: props.length }, (_, index) => props.modelValue[index] ?? ''),
)

function focusInput() {
  inputRef.value?.focus()
}

function onInput(event: Event) {
  const target = event.target as HTMLInputElement
  const filtered = target.value.replace(/\D/g, '').slice(0, props.length)
  const previousLength = props.modelValue.length

  if (filtered !== target.value) {
    target.value = filtered
  }

  emit('update:modelValue', filtered)

  if (filtered.length === props.length && previousLength < props.length) {
    inputRef.value?.blur()
    emit('complete')
  }
}

function onFocus() {
  isFocused.value = true
}

function onBlur() {
  isFocused.value = false
}
</script>

<template>
  <div class="pin-code" @click="focusInput">
    <input
      ref="inputRef"
      :value="modelValue"
      type="password"
      inputmode="numeric"
      autocomplete="one-time-code"
      :maxlength="length"
      class="pin-code__input"
      aria-label="PIN"
      @input="onInput"
      @focus="onFocus"
      @blur="onBlur"
    />

    <div class="pin-code__boxes">
      <div
        v-for="(digit, index) in digits"
        :key="index"
        class="pin-code__box"
        :class="{
          'pin-code__box--active': isFocused && modelValue.length === index,
          'pin-code__box--filled': digit !== '',
        }"
      >
        {{ digit ? '•' : '' }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.pin-code {
  position: relative;
  cursor: text;
}

.pin-code__input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0.01;
  pointer-events: none;
}

.pin-code__boxes {
  display: flex;
  justify-content: center;
  gap: 0.75rem;
}

.pin-code__box {
  width: 3.5rem;
  height: 4rem;
  border: 1px solid var(--border);
  border-radius: 0.875rem;
  background-color: var(--input-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.75rem;
  font-weight: 600;
  font-family: "Nunito", system-ui, sans-serif;
  color: var(--text);
  transition:
    border-color 0.15s ease,
    box-shadow 0.15s ease;
}

.pin-code__box--active {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--accent) 25%, transparent);
}

.pin-code__box--filled {
  color: var(--text);
}
</style>
