<script lang="ts">
import { onMount, afterUpdate } from 'svelte';
import api from '$lib/api';
import type { Message } from '$lib/types/Message';

// Zmienne
let newMessage: string = '';
let messages: Message[] = [];
let chatContainer: HTMLDivElement;
let uploading = false;

// Funkcje pomocnicze
const scrollToBottom = () => {
    if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }
};

const fetchAllMessages = async () => {
    try {
        const response = await api.get('/chat/all', {});
        messages = response.data.messages;
        scrollToBottom();
    } catch (error) {
        console.error('Error fetching all messages:', error);
    }
};

const fetchNewMessages = async () => {
    try {
        const lastTimestamp = messages.length
            ? messages[messages.length - 1].timestamp
            : new Date(0).toISOString();
        const response = await api.get('/chat', {
            params: { after: lastTimestamp }
        });
        if (response.data.messages && response.data.messages.length) {
            messages = [...messages, ...response.data.messages];
            scrollToBottom();
        }
    } catch (error) {
        console.error('Error fetching new messages:', error);
    }
};

// Zmodyfikowana funkcja sendMessage przyjmuje opcjonalnie nazwę pliku
const sendMessage = async (imageFilename: string = '') => {
    console.log('Sending message with imageFilename:', imageFilename);
    // Pozwalamy wysłać, jeśli jest tekst LUB jeśli jest zdjęcie
    if (!newMessage.trim() && !imageFilename) return;

    try {
        // Wysyłamy tekst ORAZ nazwę pliku do backendu
        // Upewnij się, że Twój backend obsługuje pole 'filename' lub 'image' w tym żądaniu!
        await api.post('/chat', { 
            message: newMessage, 
            filename: imageFilename 
        });

        newMessage = ''; // Czyścimy pole tekstowe
        await fetchAllMessages(); // Odświeżamy czat
        scrollToBottom();
    } catch (error) {
        console.error('Error sending message:', error);
    }
};

const clearChat = async () => {
    try {
        await api.post('/chat/clear');
        messages = [];
    } catch (error) {
        console.error(error);
    }
};

const uploadImage = async (file: File) => {
    uploading = true;
    const formData = new FormData();
    formData.append('file', file);
    
    try {
        const response = await api.post('/chat/upload', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
        
        const uploadedFilename = response.data.filename;
        console.log('Upload successful:', uploadedFilename);
        
        // KLUCZOWA ZMIANA:
        // Po udanym uploadzie, natychmiast wysyłamy wiadomość ze zdjęciem
        // bez czekania na kliknięcie "Send" przez użytkownika.
        await sendMessage(uploadedFilename);

    } catch (err) {
        console.error('Upload failed', err);
    } finally {
        uploading = false;
    }
};

const handleChange = (e) => {
    const file = e.target.files?.[0];
    // Jeśli plik wybrany -> upload -> auto-send
    if (file) uploadImage(file);
    
    // Resetujemy input file, żeby można było wybrać ten sam plik ponownie
    e.target.value = ''; 
};

// onMount
onMount(() => {
    fetchAllMessages();
    const interval = setInterval(fetchNewMessages, 3000);
    return () => clearInterval(interval);
});

afterUpdate(() => {
    scrollToBottom();
});
</script>

<div class="max-w-2xl mx-auto p-4">
    <h1 class="text-2xl font-bold mb-4">Chat Room</h1>

    <div class="border border-gray-300 rounded p-4 mb-4 h-80 overflow-y-auto" bind:this={chatContainer}>
        {#each messages as msg (msg.timestamp)}
            <div class="mb-4 p-2 hover:bg-gray-50 rounded">
                <div class="flex items-baseline justify-between mb-1">
                    <span class="font-semibold">{msg.username || 'User'}</span>
                    <span class="text-xs text-gray-400">{new Date(msg.timestamp).toLocaleTimeString()}</span>
                </div>
                
                {#if msg.message}
                    <p class="mb-1">{msg.message}</p>
                {/if}

                {#if msg.filename}
                    <div class="mt-2">
                         <img 
                            src={`/chat/${msg.filename}`} 
                            alt="uploaded attachment" 
                            class="chat-image rounded shadow-sm"
                            loading="lazy"
                        />
                    </div>
                {/if}
            </div>
        {/each}
    </div>

    <div class="flex space-x-2 items-center">
        <div class="relative">
            <label class="cursor-pointer bg-gray-200 hover:bg-gray-300 text-gray-700 font-semibold px-3 py-2 rounded flex items-center justify-center">
                <span>📷</span>
                <input type="file" accept="image/*" on:change={handleChange} class="hidden" />
            </label>
        </div>

        <input
            type="text"
            bind:value={newMessage}
            on:keydown={(e) => e.key === 'Enter' && sendMessage()}
            class="flex-grow border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring"
            placeholder={uploading ? "Uploading image..." : "Type your message..."}
            disabled={uploading}
        />

        <button
            on:click={() => sendMessage()}
            class="cursor-pointer bg-blue-500 hover:bg-blue-600 text-white font-semibold px-4 py-2 rounded disabled:opacity-50"
            disabled={uploading}
        >
            Send
        </button>

        <button
            on:click={clearChat}
            class="cursor-pointer bg-red-500 hover:bg-red-600 text-white font-semibold px-4 py-2 rounded"
        >
            Clear
        </button>
    </div>
</div>

<style>
    /* Usunąłem style .preview i .upload-box, bo teraz ich nie używamy w starym formie */
    
    .chat-image {
        max-width: 200px; /* Lub 100%, zależnie jak duże chcesz zdjęcia */
        max-height: 200px;
        object-fit: cover;
        border: 1px solid #ddd;
    }
    
    /* Ukrycie standardowego inputa file */
    .hidden {
        display: none;
    }
</style>