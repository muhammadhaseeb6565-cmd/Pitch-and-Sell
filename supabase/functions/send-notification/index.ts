import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as jose from 'https://deno.land/x/jose@v4.14.4/index.ts'

serve(async (req) => {
  try {
    const { record, type } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    const { data: userProfile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', record.receiver_id || record.seller_id)
      .single()
      
    if (!userProfile?.fcm_token) {
      return new Response('No FCM token found for user.', { status: 200 })
    }

    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
    const privateKeyStr = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n') || ''
    
    // Generate OAuth2 token via JWT assertion
    const alg = 'RS256'
    const privateKey = await jose.importPKCS8(privateKeyStr, alg)
    
    const jwt = await new jose.SignJWT({
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    })
      .setProtectedHeader({ alg })
      .setIssuedAt()
      .setIssuer(clientEmail!)
      .setAudience('https://oauth2.googleapis.com/token')
      .setExpirationTime('1h')
      .sign(privateKey)

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`
    })
    
    const tokens = await tokenRes.json()
    if (!tokens.access_token) {
       throw new Error('Failed to get FCM access token')
    }

    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokens.access_token}`,
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
