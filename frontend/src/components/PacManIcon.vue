<script setup lang="ts">
withDefaults(
  defineProps<{
    headOnly?: boolean
  }>(),
  { headOnly: false },
)
</script>

<template>
  <svg
    :viewBox="headOnly ? '100 115 270 170' : '0 0 680 400'"
    role="img"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
    :class="headOnly ? 'w-full h-full' : 'w-[92%] h-auto pointer-events-none translate-x-5'"
  >
    <path d="M240,200 L361,130 A140,140 0 1,0 361,270 Z" fill="#F5C842" />
    <circle cx="215" cy="145" r="14" fill="#444444" />
    <template v-if="!headOnly">
      <circle cx="430" cy="190" r="22" fill="#F5C842" />
      <circle cx="495" cy="190" r="22" fill="#F5C842" />
    </template>
  </svg>
</template>
