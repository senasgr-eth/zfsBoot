// NSBoot WebSocket Service
// Real-time updates from server

export interface WebSocketMessage {
  type: string
  data: any
  timestamp: number
}

export type MessageHandler = (data: any) => void

class WebSocketService {
  private ws: WebSocket | null = null
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectDelay = 1000
  private handlers: Map<string, MessageHandler[]> = new Map()
  private isConnecting = false

  constructor() {
    this.connect()
  }

  private getWebSocketUrl(): string {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = window.location.host
    return `${protocol}//${host}/ws`
  }

  connect() {
    if (this.isConnecting || (this.ws && this.ws.readyState === WebSocket.OPEN)) {
      return
    }

    this.isConnecting = true
    const url = this.getWebSocketUrl()

    try {
      this.ws = new WebSocket(url)

      this.ws.onopen = () => {
        console.log('WebSocket connected')
        this.isConnecting = false
        this.reconnectAttempts = 0
        this.emit('connected', {})
      }

      this.ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data)
          this.handleMessage(message)
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error)
        }
      }

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error)
        this.isConnecting = false
      }

      this.ws.onclose = () => {
        console.log('WebSocket disconnected')
        this.isConnecting = false
        this.ws = null
        this.emit('disconnected', {})
        this.reconnect()
      }
    } catch (error) {
      console.error('Failed to create WebSocket:', error)
      this.isConnecting = false
      this.reconnect()
    }
  }

  private reconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnect attempts reached')
      return
    }

    this.reconnectAttempts++
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1)

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`)

    setTimeout(() => {
      this.connect()
    }, delay)
  }

  private handleMessage(message: WebSocketMessage) {
    const { type, data } = message

    // Call all handlers for this message type
    const handlers = this.handlers.get(type) || []
    handlers.forEach(handler => {
      try {
        handler(data)
      } catch (error) {
        console.error(`Error in handler for ${type}:`, error)
      }
    })

    // Also call wildcard handlers
    const wildcardHandlers = this.handlers.get('*') || []
    wildcardHandlers.forEach(handler => {
      try {
        handler({ type, data })
      } catch (error) {
        console.error('Error in wildcard handler:', error)
      }
    })
  }

  on(messageType: string, handler: MessageHandler) {
    if (!this.handlers.has(messageType)) {
      this.handlers.set(messageType, [])
    }
    this.handlers.get(messageType)!.push(handler)
  }

  off(messageType: string, handler: MessageHandler) {
    const handlers = this.handlers.get(messageType)
    if (handlers) {
      const index = handlers.indexOf(handler)
      if (index > -1) {
        handlers.splice(index, 1)
      }
    }
  }

  send(type: string, data: any = {}) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      console.warn('WebSocket not connected, cannot send message')
      return false
    }

    try {
      const message = JSON.stringify({ type, data })
      this.ws.send(message)
      return true
    } catch (error) {
      console.error('Failed to send WebSocket message:', error)
      return false
    }
  }

  subscribe(channel: string) {
    this.send('subscribe', { channel })
  }

  unsubscribe(channel: string) {
    this.send('unsubscribe', { channel })
  }

  disconnect() {
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
  }

  isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN
  }

  private emit(event: string, data: any) {
    const handlers = this.handlers.get(event) || []
    handlers.forEach(handler => handler(data))
  }
}

// Singleton instance
export const websocket = new WebSocketService()

export default websocket
