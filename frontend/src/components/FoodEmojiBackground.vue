<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import sheet from '../assets/foodIcons.json'

const SPRITE_URL = '/food-icons.png'
const SHEET_W = sheet.sheetWidth
const SHEET_H = sheet.sheetHeight

const CELL = 72
const GAP = 34
const STRIDE = CELL + GAP

const viewport = ref({ w: 1024, h: 768 })

function updateViewport() {
  viewport.value = {
    w: window.innerWidth,
    h: window.innerHeight,
  }
}

onMounted(() => {
  updateViewport()
  window.addEventListener('resize', updateViewport)
})

onUnmounted(() => {
  window.removeEventListener('resize', updateViewport)
})

const cols = computed(() => Math.ceil((viewport.value.w * 1.6) / STRIDE) + 2)
const rows = computed(() => Math.ceil((viewport.value.h * 1.6) / STRIDE) + 2)
const totalCells = computed(() => cols.value * rows.value)

const gridStyle = computed(() => ({
  gridTemplateColumns: `repeat(${cols.value}, ${CELL}px)`,
  gridAutoRows: `${CELL}px`,
  gap: `${GAP}px`,
}))

function iconStyle(index: number) {
  const icon = sheet.icons[index % sheet.icons.length]
  const scale = CELL / Math.max(icon.w, icon.h)
  const width = icon.w * scale
  const height = icon.h * scale

  return {
    width: `${width}px`,
    height: `${height}px`,
    backgroundImage: `url('${SPRITE_URL}')`,
    backgroundRepeat: 'no-repeat',
    backgroundSize: `${SHEET_W * scale}px ${SHEET_H * scale}px`,
    backgroundPosition: `${-icon.x * scale}px ${-icon.y * scale}px`,
  }
}
</script>

<template>
  <div class="food-emoji-bg" aria-hidden="true">
    <div class="food-emoji-bg__plane">
      <div class="food-emoji-bg__grid" :style="gridStyle">
        <div
          v-for="i in totalCells"
          :key="i"
          class="food-emoji-bg__cell"
        >
          <div class="food-emoji-bg__item" :style="iconStyle(i - 1)" />
        </div>
      </div>
    </div>
  </div>
</template>
