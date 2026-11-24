import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <StatusBar style="dark" />
      <Stack screenOptions={{ headerBackTitle: 'Volver' }}>
        <Stack.Screen name="index" options={{ headerShown: false }} />
        {/* Pestañas: Galería, Mis obras y Mapa (app/(tabs)/). */}
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="pintar/[id]" options={{ title: 'Pintar' }} />
      </Stack>
    </GestureHandlerRootView>
  );
}
