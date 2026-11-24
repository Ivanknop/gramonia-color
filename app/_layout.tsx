import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <StatusBar style="dark" />
      <Stack screenOptions={{ headerBackTitle: 'Volver' }}>
        <Stack.Screen name="index" options={{ headerShown: false }} />
        <Stack.Screen name="galeria" options={{ title: 'Galería' }} />
        <Stack.Screen name="pintar/[id]" options={{ title: 'Pintar' }} />
        <Stack.Screen name="mapa" options={{ title: 'Mapa de Gramonia' }} />
      </Stack>
    </GestureHandlerRootView>
  );
}
