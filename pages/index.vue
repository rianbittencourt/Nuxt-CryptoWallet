<template>
  <div>
    <div v-if="!user">
      <p class="text-center text-xl">Please sign in to access your crypto wallet.</p>
    </div>
    
    <div v-else>
      <div v-if="currentPricesError" class="bg-red-500/20 rounded-md mb-5 p-2 flex items-center justify-center">
  <p class="text-stone-600 font-bold">Too many requests have been made. Please wait a moment and reload the page.</p>
</div>       <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-2xl font-bold mb-4">Portfolio Summary</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 bg-gray-50 rounded-lg">
            <p class="text-gray-600">Total Invested</p>
            <p class="text-2xl font-bold">${{ totalInvested.toFixed(2) }}</p>
          </div>
          <div class="p-4 bg-gray-50 rounded-lg">
            <p class="text-gray-600">Current Value</p>
            <p class="text-2xl font-bold">${{ totalCurrentValue.toFixed(2) }}</p>
          </div>
          <div class="p-4 bg-gray-50 rounded-lg" :class="totalProfitLoss >= 0 ? 'bg-green-50' : 'bg-red-50'">
            <p class="text-gray-600">Total Profit/Loss</p>
            <p class="text-2xl font-bold" :class="totalProfitLoss >= 0 ? 'text-green-600' : 'text-red-600'">
              ${{ isNaN(totalProfitLoss) || totalProfitLoss === null ? 0 : totalProfitLoss.toFixed(2) }}
              <span class="text-sm">
                ({{ totalInvested > 0 ? ((totalProfitLoss / totalInvested) * 100).toFixed(2) : 0 }}%)
              </span>
            </p>
          </div>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h2 class="text-2xl font-bold mb-4">Add New Transaction</h2>
        <form @submit.prevent="addTransaction" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Select Cryptocurrency</label>
            <select v-model="newTransaction.crypto_name" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
              <option v-for="crypto in cryptoList" :key="crypto.id" :value="crypto.id">
                {{ crypto.name }} ({{ crypto.symbol.toUpperCase() }})
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Quantity</label>
            <input v-model="newTransaction.quantity" type="number" step="any" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Purchase Price (USD)</label>
            <input v-model="newTransaction.purchase_price" type="number" step="any" required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
          </div>
          <div v-if="error" class="text-red-500 text-sm">
            {{ error }}
          </div>
          <button type="submit"
            class="w-full bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700">
            Add Transaction
          </button>
        </form>
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <h2 class="text-2xl font-bold mb-4">Your Crypto Portfolio</h2>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Crypto
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Quantity
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Purchase Price
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Current Price
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total Value
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Profit/Loss
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="transaction in transactionsWithCurrentPrice" :key="transaction.id">
                <td class="px-6 py-4 whitespace-nowrap">{{ getCryptoName(transaction.crypto_name) }}</td>
                <td class="px-6 py-4 whitespace-nowrap">{{ transaction.quantity }}</td>
                <td class="px-6 py-4 whitespace-nowrap">${{ transaction.purchase_price }}</td>
                <td class="px-6 py-4 whitespace-nowrap">${{ transaction.current_price?.toFixed(2) || 'Loading...' }}</td>
                <td class="px-6 py-4 whitespace-nowrap">${{ transaction.current_total?.toFixed(2) || 'Loading...' }}</td>
                <td class="px-6 py-4 whitespace-nowrap" :class="getProfitLossClass(transaction)">
                  ${{ transaction.profit_loss?.toFixed(2) || 'Loading...' }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  {{ new Date(transaction.created_at).toLocaleDateString() }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <button @click="deleteTransaction(transaction.id)"
                    class="text-red-600 hover:text-red-900">
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const user = useSupabaseUser()
const client = useSupabaseClient()

const transactions = ref([])
const cryptoList = ref([])
const currentPrices = ref({})
const currentPricesError = ref(false)
const error = ref('')

const newTransaction = ref({
  crypto_name: '',
  quantity: '',
  purchase_price: ''
})


const totalInvested = computed(() => {
  return transactions.value.reduce((total, t) => total + (t.quantity * t.purchase_price), 0) || 0
})


const totalCurrentValue = computed(() => {
  return transactionsWithCurrentPrice.value.reduce((total, t) => total + (t.current_total || 0), 0) || 0
})

const totalProfitLoss = computed(() => {

  return totalCurrentValue.value - totalInvested.value || 0
})

const fetchCryptoList = async () => {
  try {
    const response = await fetch('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=false')
    const data = await response.json()
    cryptoList.value = data.map(crypto => ({
      id: crypto.id,
      symbol: crypto.symbol,
      name: crypto.name
    }))
  } catch (err) {
    console.error('Error fetching crypto list:', err)
    error.value = 'Failed to load cryptocurrency list'
  }
}


const deleteTransaction = async (id) => {
  try {
    const { error: deleteError } = await client
      .from('crypto_transactions')
      .delete()
      .eq('id', id)
    
    if (deleteError) throw deleteError
    
    await fetchTransactions()
  } catch (err) {
    console.error('Error deleting transaction:', err)
    error.value = 'Failed to delete transaction'
  }
}

const fetchCurrentPrices = async () => {

  const cryptoIds = [...new Set(transactions.value.map(t => t.crypto_name))].join(',')
  if (!cryptoIds) return

  try {
    const response = await fetch(`https://api.coingecko.com/api/v3/simple/price?ids=${cryptoIds}&vs_currencies=usd`)
    const data = await response.json()
    currentPrices.value = data
  } catch (err) {
    currentPricesError.value = true
    console.error('Error fetching current prices:', err)
  }
}

const getCryptoName = (cryptoId) => {
  const crypto = cryptoList.value.find(c => c.id === cryptoId)
  return crypto ? `${crypto.name} (${crypto.symbol.toUpperCase()})` : cryptoId
}

const getProfitLossClass = (transaction) => {
  if (!transaction.profit_loss) return ''
  return transaction.profit_loss > 0 ? 'text-green-600' : 'text-red-600'
}


const transactionsWithCurrentPrice = computed(() => {
  return transactions.value.map(transaction => {
    const current_price = currentPrices.value[transaction.crypto_name]?.usd
    if (!current_price) return transaction

    const current_total = current_price * transaction.quantity
    const profit_loss = transaction.total_value ? (current_total - transaction.total_value) : 0

    return {
      ...transaction,
      current_price,
      current_total,
      profit_loss
    }
  })
})

const fetchTransactions = async () => {
  try {
    const { data, error: fetchError } = await client
      .from('crypto_transactions')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (fetchError) throw fetchError
    
    transactions.value = data
    await fetchCurrentPrices()
  } catch (err) {
    console.error('Error fetching transactions:', err)
    error.value = 'Failed to load transactions'
  }
}

const addTransaction = async () => {
  error.value = ''
  try {
    const total_value = newTransaction.value.quantity * newTransaction.value.purchase_price
    
    const { error: insertError } = await client
      .from('crypto_transactions')
      .insert([{
        user_id: user.value.id,
        crypto_name: newTransaction.value.crypto_name,
        quantity: newTransaction.value.quantity,
        purchase_price: newTransaction.value.purchase_price,
        total_value: total_value
      }])
    
    if (insertError) throw insertError
    
    newTransaction.value = {
      crypto_name: '',
      quantity: '',
      purchase_price: ''
    }
    
    await fetchTransactions()
  } catch (err) {
    console.error('Error adding transaction:', err)
    error.value = 'Failed to add transaction. Please try again.'
  }
}


onMounted(async () => {
  if (user.value) {
    await fetchCryptoList()
    await fetchTransactions()
  }
})


let priceUpdateInterval
onMounted(() => {
  priceUpdateInterval = setInterval(fetchCurrentPrices, 60000) 
})

onUnmounted(() => {
  if (priceUpdateInterval) {
    clearInterval(priceUpdateInterval)
  }
})

watch(user, async (newUser) => {
  if (newUser) {
    await fetchCryptoList()
    await fetchTransactions()
  }
})
</script>