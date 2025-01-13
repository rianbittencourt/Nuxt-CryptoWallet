<template>
  <div class="min-h-[500px] flex items-center justify-center">
    <div class="max-w-md w-full space-y-8 p-6 bg-white rounded-lg shadow">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          {{ isSignUp ? 'Sign up for an account' : 'Sign in to your account' }}
        </h2>
      </div>
      <form class="mt-8 space-y-6" @submit.prevent="handleLogin">
        <div class="rounded-md shadow-sm space-y-4">
          <div>
            <label for="email" class="sr-only">Email address</label>
            <input v-model="email" id="email" name="email" type="email" required
              class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Email address">
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <input v-model="password" id="password" name="password" type="password" required
              class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
              placeholder="Password">
          </div>
        </div>

        <div v-if="errorMessage" class="text-red-500 text-sm text-center">
          {{ errorMessage }}
        </div>

        <div>
          <button type="submit"
            class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            {{ isSignUp ? 'Sign up' : 'Sign in' }}
          </button>
        </div>

        <div class="text-center">
          <button type="button" @click="toggleMode"
            class="text-indigo-600 hover:text-indigo-500">
            {{ isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up" }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
const client = useSupabaseClient()
const email = ref('')
const password = ref('')
const errorMessage = ref('')
const isSignUp = ref(false)

const toggleMode = () => {
  isSignUp.value = !isSignUp.value
  errorMessage.value = ''
}

const handleLogin = async () => {
  errorMessage.value = ''
  try {
    if (isSignUp.value) {
      const { data, error } = await client.auth.signUp({
        email: email.value,
        password: password.value,
        options: {
          emailRedirectTo: `${window.location.origin}/login`,
          data: {
            email_confirmed: true
          }
        }
      })

      if (error) throw error
      

      if (data.user) {
        const { error: signInError } = await client.auth.signInWithPassword({
          email: email.value,
          password: password.value
        })
        
        if (signInError) throw signInError
        navigateTo('/')
      }
    } else {
      const { data, error } = await client.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })

      if (error) throw error
      
      if (data.user) {
        navigateTo('/')
      }
    }
  } catch (error) {
    console.error('Auth error:', error.message)
    errorMessage.value = error.message
  }
}
</script>