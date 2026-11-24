/** Barra de pestañas: Galería, Mis obras y Mapa. */
import { Tabs } from 'expo-router';

import { IconoGaleria, IconoMapa, IconoMisObras } from '@/components/IconosPestanas';

export default function LayoutPestanas() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#3D2C5E',
        tabBarInactiveTintColor: '#9A93A8',
      }}
    >
      <Tabs.Screen
        name="galeria"
        options={{ title: 'Galería', tabBarIcon: ({ color }) => <IconoGaleria color={color} /> }}
      />
      <Tabs.Screen
        name="mis-obras"
        options={{ title: 'Mis obras', tabBarIcon: ({ color }) => <IconoMisObras color={color} /> }}
      />
      <Tabs.Screen
        name="mapa"
        options={{
          title: 'Mapa de Gramonia',
          tabBarLabel: 'Mapa',
          tabBarIcon: ({ color }) => <IconoMapa color={color} />,
        }}
      />
    </Tabs>
  );
}
