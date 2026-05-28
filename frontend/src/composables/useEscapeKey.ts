import { onUnmounted, watch, type MaybeRefOrGetter, toValue } from 'vue'

export function useEscapeKey(
  callback: () => void,
  active: MaybeRefOrGetter<boolean> = true,
) {
  function onKeydown(e: KeyboardEvent) {
    if (e.key !== 'Escape') return
    e.preventDefault()
    callback()
  }

  function setListening(listen: boolean) {
    document.removeEventListener('keydown', onKeydown)
    if (listen) {
      document.addEventListener('keydown', onKeydown)
    }
  }

  watch(() => toValue(active), setListening, { immediate: true })

  onUnmounted(() => {
    document.removeEventListener('keydown', onKeydown)
  })
}
