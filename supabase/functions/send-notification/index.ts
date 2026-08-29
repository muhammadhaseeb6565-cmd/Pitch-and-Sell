import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://google-auth-library.deno.dev/mod.ts'

// This function listens to database triggers (e.g., new chat message, new order)
// and sends a push notification to the user's phone via FCM.
serve(async (req) => {
  try {
    const { record, type } = await req.json()
    
    // Example: { record: { receiver_id, message_text }, type: 'chat_message' }
    
    // Setup Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // 1. Fetch user FCM token from database
    const { data: userProfile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', record.receiver_id || record.seller_id)
      .single()
      
    if (!userProfile?.fcm_token) {
      return new Response('No FCM token found for user.', { status: 200 })
    }

    // 2. Fetch Firebase credentials from env
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n')
    
    // 3. Generate OAuth2 token for FCM v1 API
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    const tokens = await jwtClient.authorize()

    // 4. Send the push notification
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    const res = await fetch(https://fcm.googleapis.com/v1/projects/ + projectId + /messages:send, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: Bearer  + tokens.access_token,
      },
      body: JSON.stringify({
        message: {
          token: userProfile.fcm_token,
          notification: {
            title: type === 'order' ? 'New Sale!' : 'New Message',
            body: type === 'order' ? 'You just sold an item!' : record.message_text || 'You received a new message.',
          },
          data: {
            route: type === 'order' ? '/orders' : '/chat',
          }
        },
      }),
    })

    const responseData = await res.json()
    return new Response(JSON.stringify(responseData), { headers: { 'Content-Type': 'application/json' } })
    
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
