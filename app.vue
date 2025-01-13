<template>
  <div class="min-h-screen bg-gray-100">
    <nav class="bg-white shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <NuxtLink to="/" class="flex items-center text-xl font-bold text-gray-900">
              Crypto Wallet
            </NuxtLink>
          </div>
          <div class="flex items-center">
            <button v-if="user" @click="signOut" class="text-gray-600 hover:text-gray-900">
              Sign Out
            </button>
            <NuxtLink v-else to="/login" class="text-gray-600 hover:text-gray-900">
              Sign In
            </NuxtLink>
          </div>
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <NuxtPage />
    </main>
  </div>
</template>

<script setup>
const user = useSupabaseUser()
const client = useSupabaseClient()

const signOut = async () => {
  await client.auth.signOut()
  navigateTo('/login')
}
</script>